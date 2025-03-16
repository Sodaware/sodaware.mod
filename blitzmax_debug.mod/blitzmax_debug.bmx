' ------------------------------------------------------------------------------
' -- sodaware.blitzmax_debug
' --
' -- Contains helpers for debugging:
' --
' -- * Create logs that can be saved as formatted XML. Log messages can have
' --   different log levels to make filtering easier.
' --
' -- * Add timers to measure how long sections of code take to execute.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2008-2025 Phil Newton
' --
' -- This library is free software; you can redistribute it and/or modify
' -- it under the terms of the GNU Lesser General Public License as
' -- published by the Free Software Foundation; either version 3 of the
' -- License, or (at your option) any later version.
' --
' -- This library is distributed in the hope that it will be useful,
' -- but WITHOUT ANY WARRANTY; without even the implied warranty of
' -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' -- GNU Lesser General Public License for more details.
' --
' -- You should have received a copy of the GNU Lesser General Public
' -- License along with this library (see the file LICENSE for more
' -- details); If not, see <http://www.gnu.org/licenses/>.
' ------------------------------------------------------------------------------


SuperStrict

Module sodaware.blitzmax_debug

' -- Core.
Import "src/logger/debug_logger.bmx"

' -- Serialization.
Import "src/serializers/xml_debug_log_serializer.bmx"
