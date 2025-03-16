' ------------------------------------------------------------------------------
' -- src/logger/debug_log_constants.bmx
' --
' -- Constants used to specify a debug level.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2025 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


Const DEBUG_LEVEL_URGENT:Int	= %0001
Const DEBUG_LEVEL_GENERAL:Int	= %0010
Const DEBUG_LEVEL_LOW:Int		= %0100
Const DEBUG_LEVEL_DETAILED:Int	= %1000

Const DEBUG_LEVEL_ALL:Int		= %1111
Const DEBUG_LEVEL_DEFAULT:Int	= DEBUG_LEVEL_URGENT & DEBUG_LEVEL_GENERAL & DEBUG_LEVEL_LOW
Const DEBUG_LEVEL_LITE:Int		= DEBUG_LEVEL_URGENT & DEBUG_LEVEL_GENERAL
