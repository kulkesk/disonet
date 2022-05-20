#[
    Пример реализации ядра.
    Основная идея в том, что ядро является диспетчером событий.
    Модули, запускаясь, сообщают ядру о том, какие события они хотят обрабатывать,
    и когда возникает событие, ядро сообщает модулю что оно возникло 
    и передает ему данные, сопуствующие событию для обработки.
    Модуль, обработав данные, возвращает их и ядро может передать их для
    обработки другим модулем.
]#

import strutils
import tables

#[
    Этапы выполнения имеют имена и являются контейнерам содержащими
    - enabled: bool - включен или выключен этап
    - next: string - какой следующий этап
    - functions: массив функций
]#

# Эта переменная будет накапливать входящие данные
var data = init_table[ string, string ]()

# Переменные для многострочного текста
var multi_line:  bool   = false
var multi_quote: string = ""
var multi_text:  string = ""

# Что нужно изучить в nim:
#   Как регистрировать функции в качестве callback'ов