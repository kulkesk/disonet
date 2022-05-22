import std/[tables, algorithm, os]

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


krnl.stage = "work1"
krnl.stages["work1"] = Stage( next: "work2" )
krnl.stages["work2"] = Stage( next: "idle"  )
krnl.stages["idle"]  = Stage( next: "work1" )


proc addCallback( name: string, fn: CallbackProc, stage: string, priority: int = 100 ) =
    if stage notin krnl.stages: krnl.stages[stage] = Stage()
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
proc idle_sleep = echo "---"; sleep( 2000 )

# Одинаковый приоритет и выполняются в порядке регистрации
addCallback( "st1_fn3", st1_fn3, "work1" )
addCallback( "st1_fn2", st1_fn2, "work1" )
addCallback( "st1_fn1", st1_fn1, "work1" )

# Приоритет поменяет порядок выполнения
addCallback( "st2_fn3", st2_fn3, "work2", 300 )
addCallback( "st2_fn2", st2_fn2, "work2", 200 )
addCallback( "st2_fn1", st2_fn1, "work2", 100 )

# Добавляем колбек в несуществующий этап
addCallback( "st2_fn1", st2_fn1, "test1" )

# Паузе 2 сек
addCallback( "idle_sleep", idle_sleep, "idle", 10 )

#[
    После загрузки и инициализации модулей запускаем основной цикл.
]#

while krnl.stage != "":
    doStage( krnl.stage )
    krnl.stage = krnl.stages[krnl.stage].next
