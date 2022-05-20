#[
proc hello1 = echo "hi1"
proc hello2 = echo "hi2"

var stages = init_table[ string, string ]()

stages["stage1"]["10"][] = hello1
stages["stage1"]["10"][] = hello2
]#

import std/tables


# Таблица этапов
type ModuleProcedure = proc() {.nimcall.}
var stages: Table[ string, OrderedTable[ uint8, seq[ ModuleProcedure ] ] ]

# Таблица переключений этапов
type StageSeq = object
  disabled: bool
  next: string
var stagesSeq = initTable[ string, StageSeq ]()
stagesSeq["first"]  = StageSeq( next: "second" )
stagesSeq["second"] = StageSeq( next: "" )

stages["first"] = initOrderedTable[ uint8, seq[ ModuleProcedure ] ]()
stages["second"] = initOrderedTable[ uint8, seq[ ModuleProcedure ] ]()
stages["first"][10] = @[]
stages["first"][20] = @[]
stages["second"][10] = @[]
stages["second"][20] = @[]

proc test1 = echo "test1"
proc test2 = echo "test2"
proc test3 = echo "test3"
proc test4 = echo "test4"
proc test5 = echo "test5"
proc test6 = echo "test6"


stages["first"][10].add test1
stages["first"][10].add test2
stages["first"][20].add test3
stages["first"][20].add test4
stages["second"][10].add test5
stages["second"][20].add test6

for stage, val in stages:
  for priority, procs in val:
    for fnc in procs:
      fnc()