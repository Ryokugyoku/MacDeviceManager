//
//  GetHardwareParameter.swift
//  MacDeviceManager
//
//  Created by Maeda Mitsuhiro on 2025/09/13.
//

import Foundation
class CPUUsage {
    private var previousInfo = host_cpu_load_info()
    private var previousSize = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)

    func getCPUUsage() -> Float {
        var size = previousSize
        var cpuLoad = host_cpu_load_info()
        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }

        if result != KERN_SUCCESS {
            return 0
        }

        let userDiff = Double(cpuLoad.cpu_ticks.0) - Double(previousInfo.cpu_ticks.0)
        let systemDiff = Double(cpuLoad.cpu_ticks.1) - Double(previousInfo.cpu_ticks.1)
        let idleDiff = Double(cpuLoad.cpu_ticks.2) - Double(previousInfo.cpu_ticks.2)
        let niceDiff = Double(cpuLoad.cpu_ticks.3) - Double(previousInfo.cpu_ticks.3)

        let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
        guard totalTicks > 0 else {
            return 0
        }

        let usage = (userDiff + systemDiff + niceDiff) / totalTicks * 100.0

        previousInfo = cpuLoad
        return Float(usage)
    }
}

import MachO
class MemoryUsage {
    private let pageSize = vm_kernel_page_size // ページサイズ取得

    // メモリ使用率(％)を返す関数
    func getMemoryUsagePercent() -> Float {
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStat = vm_statistics64()
        let result = withUnsafeMutablePointer(to: &vmStat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }

        if result != KERN_SUCCESS {
            return 0
        }

        let active = Double(vmStat.active_count) * Double(pageSize)
        let inactive = Double(vmStat.inactive_count) * Double(pageSize)
        let wired = Double(vmStat.wire_count) * Double(pageSize)
        let compressed = Double(vmStat.compressor_page_count) * Double(pageSize)

        // 合計使用メモリ
        let used = active + inactive + wired + compressed

        // 物理メモリサイズ取得
        let physicalMemory = Double(ProcessInfo.processInfo.physicalMemory)

        if physicalMemory == 0 {
            return 0
        }

        // 使用率計算（％）
        let usagePercent = (used / physicalMemory) * 100.0

        return Float(usagePercent)
    }

    // メモリプレッシャー(％)を返す関数
    func getMemoryPressurePercent() -> Float {
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStat = vm_statistics64()
        let result = withUnsafeMutablePointer(to: &vmStat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }

        if result != KERN_SUCCESS {
            return 0
        }

        let wired = Double(vmStat.wire_count) * Double(pageSize)
        let compressed = Double(vmStat.compressor_page_count) * Double(pageSize)

        // 物理メモリサイズ取得
        let physicalMemory = Double(ProcessInfo.processInfo.physicalMemory)

        if physicalMemory == 0 {
            return 0
        }

        // メモリプレッシャー計算（%）
        let pressurePercent = ((wired + compressed) / physicalMemory) * 100.0

        return Float(pressurePercent)
    }
}

