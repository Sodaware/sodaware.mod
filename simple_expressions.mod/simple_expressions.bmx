' ------------------------------------------------------------------------------
' -- sodaware.simple_expressions
' --
' -- This module adds the ability to evaluate simple expressions. It supports
' -- standard mathematical operators, such as `+` and `-`, as well as custom
' -- functions and variables added from a BlitzMax Type. There is basic  support
' -- for `OR` and `AND` operations.
' --
' -- It is NOT designed to be a fully featured language (as there are no
' -- conditional constructs), but it can be useful for lightweight logic when a
' -- full scripting language is too much.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2008-2018 Phil Newton
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


Module sodaware.simple_expressions

SuperStrict

Import "src/expression_evaluator.bmx"
