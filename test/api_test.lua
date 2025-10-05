#!/usr/bin/env lua
-- NSBoot API Test Suite
-- Basic tests for API functionality

local api = require("api.init")

local tests_passed = 0
local tests_failed = 0

-- Test helper functions
local function assert_equal(actual, expected, test_name)
    if actual == expected then
        print("✓ " .. test_name)
        tests_passed = tests_passed + 1
        return true
    else
        print("✗ " .. test_name)
        print("  Expected: " .. tostring(expected))
        print("  Got: " .. tostring(actual))
        tests_failed = tests_failed + 1
        return false
    end
end

local function assert_not_nil(value, test_name)
    if value ~= nil then
        print("✓ " .. test_name)
        tests_passed = tests_passed + 1
        return true
    else
        print("✗ " .. test_name .. " - value is nil")
        tests_failed = tests_failed + 1
        return false
    end
end

local function assert_type(value, expected_type, test_name)
    local actual_type = type(value)
    if actual_type == expected_type then
        print("✓ " .. test_name)
        tests_passed = tests_passed + 1
        return true
    else
        print("✗ " .. test_name)
        print("  Expected type: " .. expected_type)
        print("  Got type: " .. actual_type)
        tests_failed = tests_failed + 1
        return false
    end
end

-- Test Suite
print("========================================")
print("NSBoot API Test Suite")
print("========================================")
print("")

-- Test 1: System Info
print("Test Group: System Info")
print("----------------------------------------")
local system_info = api.get_system_info()
assert_not_nil(system_info, "get_system_info returns data")
assert_type(system_info, "table", "get_system_info returns table")
assert_not_nil(system_info.version, "system_info has version")
assert_not_nil(system_info.hostname, "system_info has hostname")
print("")

-- Test 2: Parse Size
print("Test Group: Size Parsing")
print("----------------------------------------")
assert_equal(api.parse_size("1K"), 1024, "parse_size handles K")
assert_equal(api.parse_size("1M"), 1048576, "parse_size handles M")
assert_equal(api.parse_size("1G"), 1073741824, "parse_size handles G")
assert_equal(api.parse_size("100"), 100, "parse_size handles no unit")
print("")

-- Test 3: Images
print("Test Group: Images")
print("----------------------------------------")
local images = api.get_images()
assert_not_nil(images, "get_images returns data")
assert_type(images, "table", "get_images returns table")
print("")

-- Test 4: Clients
print("Test Group: Clients")
print("----------------------------------------")
local clients = api.get_clients()
assert_not_nil(clients, "get_clients returns data")
assert_type(clients, "table", "get_clients returns table")
print("")

-- Test 5: Snapshots
print("Test Group: Snapshots")
print("----------------------------------------")
local snapshots = api.get_snapshots()
assert_not_nil(snapshots, "get_snapshots returns data")
assert_type(snapshots, "table", "get_snapshots returns table")
print("")

-- Test 6: Metrics
print("Test Group: Metrics")
print("----------------------------------------")
local metrics = api.get_metrics()
assert_not_nil(metrics, "get_metrics returns data")
assert_type(metrics, "string", "get_metrics returns string")
assert_equal(metrics:find("nsboot_version_info") ~= nil, true, "metrics contains version info")
print("")

-- Test 7: Wake on LAN
print("Test Group: Wake on LAN")
print("----------------------------------------")
local wol_result = api.wake_client("00:11:22:33:44:55")
assert_not_nil(wol_result, "wake_client returns result")
assert_type(wol_result, "table", "wake_client returns table")
assert_not_nil(wol_result.success, "wake_client result has success field")
print("")

-- Summary
print("========================================")
print("Test Summary")
print("========================================")
print("Passed: " .. tests_passed)
print("Failed: " .. tests_failed)
print("Total:  " .. (tests_passed + tests_failed))
print("")

if tests_failed == 0 then
    print("✓ All tests passed!")
    os.exit(0)
else
    print("✗ Some tests failed")
    os.exit(1)
end
