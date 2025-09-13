import SwiftUI
import Combine
import CloudKit

enum UsageTimeUnit {
    case seconds
    case minutes
}

struct UsageRecord {
    let type: UsageType
    let usage: Double
    let timestamp: Date
    let recordID: CKRecord.ID
}

/// CloudKitを利用するUsageStore
/// CloudKit非同期処理完結後はメインスレッドで呼び出し直すこと推奨
//データ競合が起こるスレッド設計ならロックや同期機構を導入すべき
//使用目的に即して必要に応じてストレージ肥大化対策（古いレコード削除等）を考慮
class CloudUsageStore: ObservableObject {
    @Published private var secondsStorage: [String: (usage: Double, timestamp: Date)] = [:]
    
    private var timerCancellable: AnyCancellable?
    private let database = CKContainer.default().privateCloudDatabase
    
    func startPeriodicAggregation() {
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.aggregateSecondsToMinutes()
            }
    }

    func stopPeriodicAggregation() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// 秒 or 分単位保存
    func saveUsage(unit: UsageTimeUnit, type: UsageType, usage: Double, timestamp: Date = Date()) {
        switch unit {
        case .seconds:
            secondsStorage[type.rawValue] = (usage, timestamp)
        case .minutes:
            let record = CKRecord(recordType: "UsageRecord")
            record["type"] = type.rawValue as CKRecordValue
            record["usage"] = usage as CKRecordValue
            record["timestamp"] = timestamp as CKRecordValue
            database.save(record) { _, error in
                if let error = error {
                    print("CloudKit save error: \(error)")
                }
            }
        }
    }
    
    /// 全データ取得
    func fetchAll(for unit: UsageTimeUnit, completion: @escaping ([(type: UsageType, usage: Double, timestamp: Date)]) -> Void) {
        switch unit {
        case .seconds:
            let results: [(type: UsageType, usage: Double, timestamp: Date)] = secondsStorage.compactMap { (key, value) in
                guard let type = UsageType(rawValue: key) else { return nil }
                return (type: type, usage: value.usage, timestamp: value.timestamp)

            }.sorted { $0.timestamp < $1.timestamp }
            completion(results)
            
        case .minutes:
            let query = CKQuery(recordType: "UsageRecord", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            
            database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 0) { result in
                switch result {
                case .success(let queryResult):
                    var results: [(type: UsageType, usage: Double, timestamp: Date)] = []
                    for matchResult in queryResult.matchResults {
                        do {
                            let record = try matchResult.1.get()
                            if let typeRaw = record["type"] as? String,
                               let type = UsageType(rawValue: typeRaw),
                               let usage = record["usage"] as? Double,
                               let timestamp = record["timestamp"] as? Date {
                                results.append((type, usage, timestamp))
                            }
                        } catch {
                            print("Error fetching record: \(error)")
                        }
                    }
                    completion(results.sorted { $0.timestamp < $1.timestamp })

                case .failure(let error):
                    print("CloudKit fetch error: \(error)")
                    completion([])
                }
            }
        }
    }
    
    /// 最新だけ取得（例: 直近の分データ）
    func fetchLatest(for type: UsageType, completion: @escaping ((usage: Double, timestamp: Date)?) -> Void) {
        let predicate = NSPredicate(format: "type == %@", type.rawValue)
        let query = CKQuery(recordType: "UsageRecord", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { result in
            switch result {
            case .success(let queryResult):
                if let firstMatch = queryResult.matchResults.first {
                    do {
                        let record = try firstMatch.1.get()
                        if let usage = record["usage"] as? Double,
                           let timestamp = record["timestamp"] as? Date {
                            completion((usage, timestamp))
                            return
                        }
                    } catch {
                        print("Error fetching record: \(error)")
                    }
                }
                completion(nil)

            case .failure(let error):
                print("CloudKit fetch latest error: \(error)")
                completion(nil)
            }
        }
    }

    /// 秒データを集約して分単位をCloudKitに追加
    func aggregateSecondsToMinutes() {
        var usageBuckets: [UsageType: [Double]] = [:]
        var timeBuckets: [UsageType: Date] = [:]
        var keysToRemove: [String] = []

        let allSecondsData = secondsStorage.compactMap { (key, value) -> (UsageType, Double, Date)? in
            guard let type = UsageType(rawValue: key) else { return nil }
            return (type, value.usage, value.timestamp)
        }

        for record in allSecondsData {
            let (type, usage, timestamp) = record
            let minuteTimestamp = Calendar.current.date(bySetting: .second, value: 0, of: timestamp) ?? timestamp

            if let existingTimestamp = timeBuckets[type] {
                if existingTimestamp != minuteTimestamp {
                    continue
                } else {
                    usageBuckets[type]?.append(usage)
                }
            } else {
                timeBuckets[type] = minuteTimestamp
                usageBuckets[type] = [usage]
            }
            keysToRemove.append(type.rawValue)
        }

        for (type, usages) in usageBuckets {
            guard let timestamp = timeBuckets[type] else { continue }
            let avgUsage = usages.reduce(0, +) / Double(usages.count)
            saveUsage(unit: .minutes, type: type, usage: avgUsage, timestamp: timestamp)
        }

        for key in keysToRemove {
            secondsStorage.removeValue(forKey: key)
        }
    }
}
