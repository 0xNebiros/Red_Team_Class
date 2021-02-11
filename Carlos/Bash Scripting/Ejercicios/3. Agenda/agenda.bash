#!/bin/bash
#    echo $( jq --arg field $2 --arg value $input 'select(.[$field]==$value)' <<< $4)

# Formato de texto ANSI
ansi_red="\033[0;31m"
ansi_bold="\u001b[1m"
ansi_underline="\u001b[4m"
ansi_reset="\e[0m"

function list_teams {
  teams=$( jq '.team' <<< "$json_file" )
  for i in ${teams[@]};
  do
    # Elimina mediante sed el primer y el último caracter que son comillas (cosas del jq).
    i=$( echo "$i" | sed 's/^.//;s/.$//' )
    echo "Team $i:"

    for c in {0..5}; do
      echo -e "\t- $( jq --argjson counter $c \
      --arg team "$i" \
      'select(.team==$team) | .composition[$counter].pokemon' teams.json \
      | sed 's/^.//;s/.$//')"
    done
  done
  echo -e "\n\n"
}

function search_team {
  echo -n "Insert the team to search: "
  read input

  json=$( jq --arg filter $input '. | select(.team == $filter)' <<< "$json_file" )

  clear

  # Comprueba que el json creado este informado, si no lo esta sale de la función mostrando un mensaje de error.
  echo $json | grep -q "team"
  if [[ $? -ne 0 ]]; then
    echo -e "Team $input not found.\n\n"
    return 0
  fi

  # Muestra los datos obtenidos
  echo "Team: $( jq '.team' <<< $json | sed 's/^.//;s/.$//')"
  echo -e "Composition:"

  for i in {0..5}
  do
    echo -e "\tPokemon $((i+1)): $( jq --argjson c $i '.composition[$c].pokemon' <<< $json | sed 's/^.//;s/.$//')"

    for x in ${pokemon_data[@]};
    do
      if [[ $x =~ ^move. ]]; then
        c=$( echo ${x:4:1} )
        echo -e "\t\t${x^}: $( jq --argjson c $c --arg key $x '.composition[$c].data.moves[$c]' <<< $json  | sed 's/^.//;s/.$//')"
      else
        # Key por key va sacando us valor para mostrarlo por pantalla.
        # Para poder mostrar el campo que me interesa de data tengo que usar el data[$key], de esa forma encuentra el key.
        # Tiene que ser sin el punto, muy importante.
        echo -e "\t\t${x^}: $( jq --argjson c $i --arg key $x '.composition[$c].data[$key]' <<< $json  | sed 's/^.//;s/.$//')"
      fi
    done
  done

  option=0

  while [ $option -ne 3 ]; do
    echo -e "\nTeam Options.\n1.Edit\n2.Delete\n3.Back."
    echo -n "Introduce your option: "
    read option
    clear

    if [[ $option =~ ^[1-3]$ ]]; then
      case $option in
        1)
        edit_team
        ;;
        2)
        delete_team
        ;;
      esac

    else
      echo -e "${ansi_red}¡Opción invalida!\n${ansi_reset}Por favor, ${ansi_bold}${ansi_underline}introduce un número del 1 al 3${ansi_reset} para indicar que acción deseas realizar.\n\n"
    fi
  done
  clear
}

function new_team {
  check_repeated "Introduce new team name:" "team" ".team" "$json_file"  #Llama a la varible de guardar datos para obtener el equipo.

  # Crea una variable para la que ejecuta jq, de forma que deja un json creado con el nombre del equipo y un array para su composición.
  json=$( jq -n --arg team "$input" '{team: $team, composition: []}')

  # Bucle que se ejecuta 6 veces, una por pokemon del equipo.
  for i in {0..5}
  do
    clear
    # Pide un pokemon y comprueba que no este repetido dentro del equipo.
    check_repeated "Introduce name for pokemon $((i+1)):" "pokemon" ".composition[].pokemon" "$json"

    # Hace un append del nombre del pokemon al json creado.
    # Para hacer un append dentro de composition se usa el .composition, de esa forma se indica que se accede a ese campo para modificarlo.
    # Entre [] se ejecuta ".composition | length", esto es para ver la longitud total de dicho array de esta forma no se sobreescribirá un registro ya existente, sino que se añade al final.
    # Despues se utiliza "|= .+" para hacer un append, no tengo muy claro por que hacen falta 4 simbolos para un append, pero ahi estan.
    # Para que jq utilice correctamente el json se le tiene que pasar como literal usando "<<<".
    json=$( jq --arg pokemon "$input" \
    '.composition[.composition | length] |= .+ {"pokemon": $pokemon, "data": {"moves": []}}' <<< $json )

    clear
    echo  "Introduce data for $input:"

    # Recorre el array con los literales de los datos para pedirlos uno a uno.
    for x in ${pokemon_data[@]};
    do
      # Si el dato que se va a introducir es un moviminento (que no se pueden repetir) llama a la función de leer sin repetir
      # y lo guarda en el array de movimientos.
      # Sino lo lee sin mas y lo guarda en data.
      if [[ $x =~ ^move. ]]; then
        check_repeated "${x^}: " "move" ".composition[$i].data.moves[]" "$json"
        json_append='.composition[$counter].data.moves[.composition[$counter].data.moves | length] |= $value'
      else
        echo -n "${x^}:"
        read input
        json_append='.composition[$counter].data |= .+ { ($key) : $value}'
      fi

      # Para pasar un argumento a jq que tendrá que usar como un numero este tiene que ir con argjson y no con arg.
      # Tampoco puede llevar comillas (obvio).
      json=$(jq --argjson counter $i \
      --arg key $x \
      --arg value "$input" \
      "$json_append" <<< $json)

    done
  done

  # Actualiza el fichero y la variable creada a partir de este.
  jq '.' <<< "$json" >> teams.json
  json_file="$json_file $( jq '.' <<< "$json" )"
}

function edit_team {
  echo "funcion no incorporada aun"
}

function delete_team {
  json_file=$( jq 'del(. | select(.team=="pokimon"))' teams.json )
  echo $json_file


}

# Función para leer un valor y comprobar que este no este repetido dentró del json.
# $1: ask, $2: error, $3: route, $4: json
function check_repeated {
  repeated=0 # Booleano para comprobar si un valor esta repetido.

  while [[ repeated -eq 0 ]]; do
    echo -n $1
    read input

    jq $3 <<< $4 | grep -q "$input" # Busca todos los valores que coinciden con la key recibida y lo pasa a grep que compara con el valor escrito en silecnio por la q.
    repeated=$?

    if [[ repeated -eq 0 ]]; then
      clear
      echo -e "${ansi_red}${2^} $input already exists.${ansi_reset}"
    fi
  done
}




# Función para eliminar

#Variables globales.
pokemon_data=(nickname item ability move1 move2 move3 move4)   # Crea un array con los campos que se introducirán al crear un pokemon. Asi es mas facil recorrerlos con un bucle.
option=0
input="" # Variable utilizada para los reads.
json="" # Variable utilizada para guardar de forma temporal el json que se va a añadir al fichero.
json_file="" # Variable utilizada para guardar el json completo.

# Comprueba si existe el json necesario, si lo guarda en una variable.
# Si no existe lo crea.
if test -f teams.json; then
  json_file=$( jq '.' teams.json )
else
  touch teams.json
fi

# Leer la opción introducida por el usuario hasta que esta sea una opción valida
while [ $option -ne 6 ]; do

  # echo -e muestra los saltos de linea del string.
  echo -e "Herramienta de gestión de equipos pokemon.\n1. Buscar.\n2. Nuevo.\n3. Listar.\n4. Salir.\n"
  # echo -n muestra un string sin el salto de linea por defecto.
  echo -n "Introduce tu opción: "
  read option
  clear

  if [[ $option =~ ^[1-4]$ ]]; then
    # Evalua la opción que ha introducido el usuario y en base a esto llama a la función que ejecuta la acción.
    case $option in
      1)
        search_team
        ;;
      2)
        new_team
        ;;
      3)
        list_teams
        ;;
    esac

  else
    echo -e "${ansi_red}¡Opción invalida!\n${ansi_reset}Por favor, ${ansi_bold}${ansi_underline}introduce un número del 1 al 4${ansi_reset} para indicar que acción deseas realizar.\n\n"

  fi
done
