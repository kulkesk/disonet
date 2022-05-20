import std/[tables, algorithm]

type
  CallbackProc = proc() {.nimcall.}

  Callback = object
    priority: int
    disabled: bool
    name: string
    fn: CallbackProc
  
  Stage = object
    disabled: bool
    next: string
    entries: seq[Callback]
  
  Krnl = object
    stage: string
    stages: Table[string, Stage]


var krnl: Krnl


krnl.stages = toTable({
  "stage 1": Stage( next: "stage 2" ),
  "stage 2": Stage()
})
krnl.stage = "stage 1"


proc addCallback( name: string, fn: CallbackProc, stage: string, priority: int ) =
  krnl.stages[stage].entries.add Callback( name: name, priority: priority, fn: fn )

  # Sort callbacks in-place by their priority, from lowest
  # to highest
  krnl.stages[stage].entries.sort do ( x, y: Callback ) -> int:
    cmp( x.priority, y.priority )


proc doStage( stage = "" ) =
  if stage notin krnl.stages or krnl.stages[stage].disabled:
    return

  for entry in krnl.stages[stage].entries:
    entry.fn()




#[
    Тут загрузка модулей (dll).
    Модули регистрируют свои функции.
    И в конце запускается цикл.
]#

proc st1_fn1 = echo "stage 1, func 1"
proc st1_fn2 = echo "stage 1, func 2"
proc st1_fn3 = echo "stage 1, func 3"
proc st2_fn1 = echo "stage 2, func 1"
proc st2_fn2 = echo "stage 2, func 2"
proc st2_fn3 = echo "stage 2, func 3"

# Одинаковый приоритет и выполняются в порядке регистрации
addCallback( "st1_fn3", st1_fn3, "stage 1", 10 )
addCallback( "st1_fn2", st1_fn2, "stage 1", 10 )
addCallback( "st1_fn1", st1_fn1, "stage 1", 10 )

# Приоритет поменяет порядок выполнения
addCallback( "st2_fn3", st2_fn3, "stage 2", 30 )
addCallback( "st2_fn2", st2_fn2, "stage 2", 20 )
addCallback( "st2_fn1", st2_fn1, "stage 2", 10 )

#[
    После загрузки и инициализации модулей запускаем основной цикл.
]#

while krnl.stage != "":
  doStage( krnl.stage )
  krnl.stage = krnl.stages[krnl.stage].next
