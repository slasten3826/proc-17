#!/usr/bin/env lua

package.path = "./?.lua;./?/init.lua;" .. package.path

os.exit(require("cli.proc17").main(arg))
