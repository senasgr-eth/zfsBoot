-- Luacheck configuration for NSBoot

-- Ignore some common warnings
std = "lua53"
ignore = {
    "113",  -- Accessing undefined variable (for ngx globals)
    "212",  -- Unused argument
    "213",  -- Unused loop variable
    "631",  -- Line is too long
}

-- Global variables from OpenResty/Nginx
globals = {
    "ngx",
}

-- Read-only globals
read_globals = {
    "ngx",
    "require",
    "io",
    "os",
    "string",
    "table",
    "math",
    "tonumber",
    "tostring",
    "print",
    "pcall",
    "pairs",
    "ipairs",
    "type",
    "assert",
    "error",
}

-- Files to exclude
exclude_files = {
    "src/ipxe/",  -- Exclude iPXE files
}

-- Maximum line length
max_line_length = 120

-- Maximum code complexity
max_cyclomatic_complexity = 20
