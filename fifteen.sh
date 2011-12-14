#!/bin/bash
# console 'fifteen' game by Oleks Tangelov.
# Special thanks to Evgeny Stepanischev http://bolknote.ru for idea and beatiful example (http://bolknote.ru/2011/09/15/~3408#n30691).
# Two  things left in TODO - 1. randomize starting location 2. normal exit.

#adding a debug mode

DEBUG=0
if [ $# -eq 1 ]; then
 DEBUG=$1
fi

# Необходимые нам клавиатурные коды
KUP=1b5b41
KDOWN=1b5b42
KLEFT=1b5b44
KRIGHT=1b5b43
KSPACE=20
KESC=33

# Клавиатурные комбинации извстной длины
SEQLEN=(1b5b4. [2-7]. [cd]... [89ab].{5} f.{7})

#Коробка
declare -a XY
declare -a InitArray

#Собственно костяшки от 1 до 15
DIGITS=(1 2 3 4 5 6 7 8 9 A B C D E F ' ')

# Курсор
CX=1 CY=1

# Версия bash
BASH=(${BASH_VERSION/./ })

# Восстановление экрана
function Restore {
    echo -ne "\033[10B\033[?25h\033[0m"
    stty "$ORIG" 2>/dev/null
    (bind '"\r":accept-line' 2>/dev/null)
}

trap Restore exit

# Выключаем Enter
(bind -r '\r' 2>/dev/null)
# Выключаем остальную клавиатуру
ORIG=`stty -g`
stty -echo

# Убирам курсор
echo -e "\033[?25l"

function CheckColor {
     echo -n ${1:0:1}
}

# Очистка клавиатурного буфера
function ClearKeyboardBuffer {
	# Быстро — через bash 4+
    [ $BASH -ge 4 ] && while read -t0.1 -n1 -rs; do :; done && return

    # Быстро — через zsh
    which zsh &>/dev/null && zsh -c 'while {} {read -rstk1 || break}' && return

    # Медленно — через bash 3-
    local delta
    while true; do
        delta=`(time -p read -rs -n1 -t1) 2>&1 | awk 'NR==1{print $2}'`
        [[ "$delta" == "0.00" ]] || break

		echo $delta
    done
}

function CheckResult {
	local x y xy
	
     for y in {1..4}; do
         for x in {1..4}; do
			let xy="$x +100*$y"
             if [ ! "${XY[$xy]:-S }" = "D${DIGITS[$x+4*$y-5]}" ]; then
                return 1
             fi
         done
     done
     return 0;
}

# Реакция на нажатие Space и Enter — передвинуть ли цифру
function SpaceEvent {
	local xy a
    # Проверяем, есть ли цифра под курсором
    let xy="$CX+$CY*100"
	
	#Под курсором пустое место
	if [ "${XY[$xy]:-S }" = "D " ]; then
	 return 0
	fi
	
	#Не правая колонка. и справа пусто.
	if [ $CX -lt 4 ]; then
	    a=$(($CX+1))
	    let ax="$a+$CY*100"
	    if [ "${XY[$ax]:-S }" = "D " ]; then
	       #Поменять местами
	       XY[$ax]="${XY[$xy]:-S }"
	       XY[$xy]="D "
	    fi
    fi
	#Не левая колонка. и слева пусто.
	if [ $CX -gt 1 ]; then
	    a=$(($CX-1))
	    let ax="$a+$CY*100"
	    if [ "${XY[$ax]:-S }" = "D " ]; then
	       #Поменять местами
	       XY[$ax]="${XY[$xy]:-S }"
	       XY[$xy]="D "
	    fi
    fi
	#Не верхняя строка. и сверху пусто.
	if [ $CY -gt 1 ]; then
	    a=$(($CY-1))
	    let ax="$CX+$a*100"
	    if [ "${XY[$ax]:-S }" = "D " ]; then
	       #Поменять местами
	       XY[$ax]="${XY[$xy]:-S }"
	       XY[$xy]="D "
	    fi
    fi
	#Не нижняя строка. и снизу пусто.
	if [ $CY -lt 4 ]; then
	    a=$(($CY+1))
	    let ax="$CX+$a*100"
	    if [ "${XY[$ax]:-S }" = "D " ]; then
	       #Поменять местами
	       XY[$ax]="${XY[$xy]:-S }"
	       XY[$xy]="D "
	    fi
    fi
    #Проверяем последоватольность. Если вернулось 1 - значит собрано
    if CheckResult; then
		exit
	fi
}
# Реакция на клавиши курсора
function React {
    case $1 in
        $KLEFT)
              if [ $CX -gt 1 ]; then
                  CX=$(($CX-1))
                  PrintBoard
              fi
           ;;

        $KRIGHT)
              if [ $CX -lt 4 ]; then
                  CX=$(($CX+1))
                  PrintBoard
              fi
            ;;

        $KUP)
              if [ $CY -gt 1 ]; then
                  CY=$(($CY-1))
                  PrintBoard
              fi
           ;;

        $KDOWN)
              if [ $CY -lt 4 ]; then
                  CY=$(($CY+1))
                  PrintBoard
              fi
            ;;
         $KESC)
			exit 0
    esac

    # Отдаём события клавиатуры в сеть
#    [ "$OURMOVE" ] && ToNet $1
}

# Вывод доски
function PrintBoard {
     local x y c ch
     local colors=('48;5;209;37;1' '48;5;94;37;1')

#     PrintBoardLetters

     for y in {1..4}; do
     #   PrintBoardDigit $y

        for x in {1..4}; do
            c=${colors[($x+$y) & 1]}
            ch=${XY[$x+100*$y]}

            if [[ $CX == $x && $CY == $y ]]; then
                c="$c;7"
#                [ "$TAKEN" ] && ch=$TAKEN
#                [ $MYCOLOR == B ] && c="$c;38;5;16"
            fi

            [[ $(CheckColor "$ch") == "W" ]] && c="$c;38;5;16"

            echo -en "\033[${c}m${ch:1:1} \033[m"
        done

        #PrintBoardDigit $y
        echo
     done

     #PrintBoardLetters

     echo -e "\033[05A"
}


# Проверка совпадения с известной клавиатурной комбинацией
function CheckCons {
    local i

    for i in ${SEQLEN[@]}; do
        if [[ $1 =~ ^$i ]]; then
            return 0
        fi
    done

    return 1
}


# Функция реакции на клавиатуру, вызывает React на каждую нажатую клавишу,
# кроме KSPACE — на неё возвращается управление

function PressEvents {
    local real code action

    # Цикл обработки клавиш, здесь считываются коды клавиш,
    # по паузам между нажатиями собираются комбинации и известные
    # обрабатываются сразу
    while true; do
        # измеряем время выполнения команды read и смотрим код нажатой клавиши
        # akw NR==1||NR==4 забирает только строку №1 (там время real) и №4 (код клавиши)
        eval $( (time -p read -r -s -n1 ch; printf 'code %d\n' "'$ch") 2>&1 |
        awk 'NR==1||NR==4 {print $1 "=" $2}' | tr '\r\n' '  ')

        # read возвращает пусто для Enter и пробела, присваиваем им код 20,
        # а так же возвращаются отрицательные коды для UTF8
        if [ "$code" = 0 ]; then
            code=20
        else
             [ $code -lt 0 ] && code=$((256+$code))

             code=$(printf '%02x' $code)
        fi

        if [ $code = $KSPACE ]; then
            
            SpaceEvent && return
            continue
        fi

        # Если клавиши идут подряд (задержки по времени нет)
        if [ $real = 0.00 ]; then
            seq="$seq$code"

            if CheckCons $seq; then
                React $seq
                seq=
            fi

        # Клавиши идут с задержкой (пользователь не может печатать с нулевой задержкой),
        # значит последовательность собрана, надо начинать новую
        else
            [ "$seq" ] && React $seq
            seq=$code

            # возможно последовательность состоит из одного символа
            if CheckCons $seq; then
                React $seq
                seq=
            fi
        fi
    done
}

function CheckInit {
	local x y xy
	
     for y in {1..4}; do
         for x in {1..4}; do
			let xy="$x+100*$y"
			if [ "${XY[$xy]:-S }" = "${ch}" ]; then
				return 1;
			fi
		done
	done
	return 0;
}
# Первичное заполнение коробочки
function FillBoard {
     local x y ch r

     let range=16
	if [ $DEBUG = 1 ]; then
		for y in {1..4}; do
			for x in {1..4}; do
				ch=D${DIGITS[$x+4*$y-5]}	
				XY[$x+100*$y]=$ch
			done
		done
	else
		for y in {1..4}; do
			for x in {1..4}; do
				until false 
				do
					r=$RANDOM
					let "r %= $range"
					ch=D${DIGITS[$r]}
					if CheckInit $ch; then
						break
					fi
				done
				
				XY[$x+100*$y]=$ch
			done
		done
	fi
}


FillBoard

PrintBoard


while true; do
    ClearKeyboardBuffer
    PressEvents
    PrintBoard
done
