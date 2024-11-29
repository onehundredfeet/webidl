#!/bin/bash
haxe -cp generator  -lib hl-idl --macro "Generator.generate(\"hl\", true)"
haxe -cp generator  -lib hl-idl --macro "Generator.generate(\"jvm\", true)"
haxe -cp generator  -lib hl-idl --macro "Generator.generate(\"hxcpp\", true)"
haxe -cp generator  -lib hl-idl --macro "Generator.generate(\"enscripten\", true)"