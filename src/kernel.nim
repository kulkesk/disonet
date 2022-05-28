#[
    Этот еще не реализовано:
    Запускаясь, программа ищет рядом с собой файл private.key и
    если его нет, то генерирует закрытый ключ и скидывает его в файл.
    Такой подход позволит запускать несколько экземпляров программы
    на одном компьютере даже не изучая параметры коммандной строки.
]#

#[
    Реализация ядра.
    Основная идея в том, что ядро является диспетчером событий.
    Модули, инициализируясь, сообщают ядру о том, какие события они хотят обрабатывать,
    для этого они регистрируют процедуры в качестве колбеков на нужные им события.
    Когда возникает событие, ядро вызывает все колбеки привязанные к данному событию.
    Модули работают с глобальными данными, изменяя их.
    Для этого будет создан глобальный объект содержащий эти данные.
]#

import tables
import strutils
import algorithm
import os

type
    CallbackProc = proc() {.nimcall.}

    Callback = object
        priority: int
        disabled: bool
        name: string
        fn: CallbackProc
  
    Event = object
        disabled: bool          # для отключения события
        next: string            # какое следующее событие
        entries: seq[Callback]  # последовательность функций зарегистрированных на это событие
  
    Krnl = object
        event: string
        events: Table[string, Event]


var krnl: Krnl
# Начальное событие
krnl.event = "work1"
# Цепочка событий
krnl.events["work1"] = Event( next: "work2" )
krnl.events["work2"] = Event( next: "idle" )
krnl.events["idle"]  = Event( next: "work1" )


proc addCallback( name: string, fn: CallbackProc, event: string, priority: int = 100 ) =
    if event notin krnl.events: krnl.events[event] = Event()
    krnl.events[event].entries.add Callback( name: name, priority: priority, fn: fn )

    # Sort callbacks in-place by their priority, from lowest
    # to highest
    krnl.events[event].entries.sort do ( x, y: Callback ) -> int:
        cmp( x.priority, y.priority )


proc doEvent( event = "" ) =
    if event notin krnl.events or krnl.events[event].disabled:
        return

    for entry in krnl.events[event].entries:
        entry.fn()


#[
    Проверяем существует ли конфиг-файл ядра и если нет, то создаем его.
]#
if not fileExists( "kernel.cfg" ):
    let config = [
        "loadmodule module1.dll",
        "loadmodule module2.dll"
    ]
    writeFile( "kernel.cfg", join( config, "\n" ) )

#[
    Считываем конфиг-файл, парсим и выполняем содержащиеся в нем команды.
    loadmodule module1.dll
    loadmodule module2.dll
]#
let config = readFile( "kernel.cfg" )
let lines  = config.split( "\n" )

# Переменные для многострочного текста
var multi_line:  bool   = false
var multi_quote: string = ""
var multi_text:  string = ""

for line in lines:

    # Разбиваем строку на команду и параметры
    var cmd_arg = line.split( " ", maxsplit = 1 )

    # Пропустить пустую строку
    if cmd_arg[0] == "":
        continue

    # Добавляем аргументы если их нет
    if cmd_arg.len < 2:
        cmd_arg.add( "" )

    # Поступила многострочная команда
    if cmd_arg[0] == "text" and cmd_arg[1] != "":
        multi_quote = cmd_arg[1]
        multi_line  = true
        continue

    # Если режим многострочности, то накапливаем текст
    if multi_line:
        if cmd_arg[0] != multi_quote:
            if multi_text.len > 0:
                multi_text &= "\n"
            multi_text &= line
            continue
        else:
            cmd_arg[0] = "text"
            cmd_arg[1] = multi_text
            multi_line = false
            multi_text = ""

    case cmd_arg[0]:

    of "stop":

        stderr.writeLine( "stop program" )
        quit( QuitSuccess )

    of "loadmodule":

        stderr.writeLine( "load module \"", cmd_arg[1], "\"" )
        #[
            Тут загрузка модулей (dll).
            Модули регистрируют свои функции.
            И в конце запускается цикл.
        ]#

proc ev1_fn1 = echo "event 1, func 1"
proc ev1_fn2 = echo "event 1, func 2"
proc ev1_fn3 = echo "event 1, func 3"
proc ev2_fn1 = echo "event 2, func 1"
proc ev2_fn2 = echo "event 2, func 2"
proc ev2_fn3 = echo "event 2, func 3"
proc idle_sleep = echo "---"; sleep( 10000 )

# Одинаковый приоритет и выполняются в порядке регистрации
addCallback( "ev1_fn3", ev1_fn3, "work1" )
addCallback( "ev1_fn2", ev1_fn2, "work1" )
addCallback( "ev1_fn1", ev1_fn1, "work1" )
krnl.events["work1"].next = "work2"

# Приоритет поменяет порядок выполнения
addCallback( "ev2_fn3", ev2_fn3, "work2", 300 )
addCallback( "ev2_fn2", ev2_fn2, "work2", 200 )
addCallback( "ev2_fn1", ev2_fn1, "work2", 100 )
krnl.events["work2"].next = "idle"

# Добавляем колбек в несуществующий этап
addCallback( "ev2_fn1", ev2_fn1, "test1" )

# Паузе 2 сек
addCallback( "idle_sleep", idle_sleep, "idle", 10 )
krnl.events["idle"].next = "work1"

#[
    После загрузки и инициализации модулей запускаем основной цикл.
]#

krnl.event = "work1"
while krnl.event != "":
    doEvent( krnl.event )
    krnl.event = krnl.events[krnl.event].next
