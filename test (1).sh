check(){
id=$1
  # Validate the ID format (7-digit number)
    if ! [[ "$id" =~ ^[0-9]{7}$ ]]; then
        echo "Invalid ID format. ID should be a 7-digit number."
        exit 
        
    fi
}

ubnormal() {
    local testname
    local minrange
    local maxrange
    local count=0

    declare -A name
    local i=1

    # Extract test names from medicalTest.txt
    while testname=$(sed -n "${i}p" medicalTest.txt | grep -i "Name: " | cut -d':' -f2 | cut -d';' -f1 | cut -d'(' -f2 | cut -d')' -f1); do
        if [ -z "$testname" ]; then
            break # Break if no more test names are found
        fi
        name[$i]="$testname"

        minrange=$(grep -i "$testname" medicalTest.txt | grep -oP 'Range: > \K[0-9.]+')
        maxrange=$(grep -i "$testname" medicalTest.txt | grep -oP ' < \K[0-9.]+')

        # Set default range if not defined
        if [ -z "$minrange" ]; then
            minrange=0
        fi

        if [ -z "$maxrange" ]; then
            echo "Ranges for test name '$testname' are not defined correctly."
            continue
        fi

        # Search for and display abnormal results
        while IFS=, read -r patient_id test_date value unit status; do
            # Clean the value and convert to numeric format
            value=$(echo "$value" | sed 's/[^0-9.]//g')

            # Compare value against the range
            if [[ -n "$value" ]] && { (( $(echo "$value < $minrange" | bc) == 1 )) || (( $(echo "$value > $maxrange" | bc) == 1 )); }; then
                echo "$patient_id, $test_date, $value, $unit, $status"
                count=$((count + 1))
            fi
        done < <(grep -i "$testname" midecalRecord.txt)

        i=$((i + 1))
    done < <(sed -n '1,${p;d}' medicalTest.txt)  # Adjust to ensure we process the entire file

    # Check if any abnormal tests were found
    if (( count == 0 )); then
        echo "There are no abnormal tests found."
    fi
}

avg() { # for choice 4

    declare -A name
    local i=1 # Starting from 1 as `sed -n` uses line numbers starting from 1

    # Extract test names from medicalTest.txt
    while testname=$(sed -n "${i}p" medicalTest.txt | grep -i "Name: " | cut -d':' -f2 | cut -d';' -f1 | cut -d'(' -f2 | cut -d')' -f1); do
        if [ -z "$testname" ]; then
            break # Break if no more test names are found
        fi
        name[$i]="$testname"
        i=$((i + 1))
    done

    # Calculate the average for each test name
    for key in "${!name[@]}"; do
        testname="${name[$key]}"
        sum=0
        count=0

        # Clean and process test names for consistent matching
        testname=$(echo "$testname" | xargs)  # Remove leading/trailing spaces

        while IFS=, read -r patient_id test_date value unit status; do
            # Clean the value and convert to numeric format
            value=$(echo "$value" | sed 's/[^0-9.]//g')

            # Ensure that we are only processing relevant records
            if [[ "$testname" =~ ^[[:space:]]* ]]; then
                sum=$(echo "$sum + $value" | bc)
                count=$((count + 1))
            fi
        done < <(grep -i "$testname" midecalRecord.txt)

        if [ $count -ne 0 ]; then
            avg=$(echo "scale=2; $sum / $count" | bc)
            printf "Test Name: %s, Average Value: %.2f\n" "$testname" "$avg"
        else
            printf "Test Name: %s, No data available\n" "$testname"
        fi
    done
}
search() {
    local id="$1"
    local test_name
    local minrange
    local maxrange
    local count=0

   check "$id"
   

    # Extract the test names associated with the given ID from medicalRecord.txt
    test_name=$(grep -i "$id" midecalRecord.txt | cut -d':' -f2 | cut -d',' -f1 )
    if [ -z "$test_name" ]; then
        echo "ID not found in medicalRecord.txt."
        return 1
    fi

    # Extract the min and max range for the test name from medicalTest.txt
    minrange=$(grep -i "$test_name" medicalTest.txt | grep -oP 'Range: > \K[0-9.]+')
    maxrange=$(grep -i "$test_name" medicalTest.txt | grep -oP ' < \K[0-9.]+' )
    
    # Handle cases where ranges might not be defined
    if [ -z "$minrange" ]; then
        minrange=0
    fi

    if [ -z "$maxrange" ]; then
        echo "Ranges for test name '$test_name' are not defined correctly."
        return 1
    fi

    # Search for and display abnormal results from medicalRecord.txt
    while IFS=, read -r patient_id test_date value unit status; do
        # Clean the value and convert to numeric format
        value=$(echo "$value" | sed 's/[^0-9.]//g')

        # Compare value against the range
    if [[ -n "$value" ]] && { (( $(echo "$value < $minrange" | bc) == 1 )) || (( $(echo "$value > $maxrange" | bc) == 1 )); }; then
echo "$patient_id, $test_date, $value, $unit, $status"
count=$((count + 1))
fi
    done < <(grep -i "$id" midecalRecord.txt)

    # Check if any abnormal tests were found
    if (( count == 0 )); then
        echo "There are no abnormal tests found."
    fi
}


menu() {
printf "\n\nWelcome to my programe\nplease enter the number of operation:\n"
printf "1- Add anew medical test record.\n"
printf "2- Search for a test by patient ID.\n"
printf "3- Searching for up normal tests.\n"
printf "4- Average test value.\n"
printf "5- Update an existing test result.\n"
printf "6- Delete a test.\n"
printf "7- exit\n"
printf "\n"

read operation

if [ $operation -eq 1 ]
then
	printf "enter patiant id cosisit of 7 digit:\n"
	read id
	check "$id"

	printf "enter test name:\n"
	read testName

	printf "enter the test date(YYYY-MM):\n"
	read datee

	printf "enter test result in floating point:\n"
	read floatingResult

	printf "enter test result unit:\n"
	read unitResult

	printf "enter test status(Pending,Completed,Reviewed):\n"
	read resultStatus

	echo "${id}: ${testName}, ${datee}, ${floatingResult}, ${unitResult}, ${resultStatus}" >>  midecalRecord.txt
	printf "the test record have been added\n"
	printf "\n"

 
elif [ $operation -eq 2 ]
then
	
		while true
		do
		printf "\n choose one of te following:\nA- Retrieve all patient tests.\n"
		printf "B- Retrieve all up normal patient tests.\n"
		printf "C- Retrieve all patient tests in a given specific period.\n"
		printf "D- Retrieve all patient tests based on test status.\n"
		printf "E- exit.\n\n"	
		
		read option

		case $option in
		A)  echo "enter id"
                read id
                check "$id"
		grep "^${id}:" midecalRecord.txt || echo "no test found for patient with id ${id} "
	        printf "\n" ;;

		B) echo "enter id"
                read id
		
         search "$id"

		printf "\n" ;;

		C) echo "enter id"
                read id
                check "$id"
		echo "enter start date(YYYY-MM):"
		read sdate
		echo "enter end date(YYYY-MM):"
		read edate 

		found=0

		grep "${id}:" midecalRecord.txt | while read line; do
		testDate=$(echo $line | cut -d ',' -f2 | tr -d ' ')
		if [[ "$testDate" > "$sdate" && "$testDate" < "$edate" ]]; then
			echo "$line"
			found=$((found+1))
		fi
		done
		 if [ $found -eq 0 ]; then
		 echo "no tests found for patient with id ${id} in the period "
		fi
		printf "\n" ;;
		D)echo "enter id"
                read id
                echo "enter test status(pending,completed,recviewed):"
                read resultStatus
grep "^${id}:" midecalRecord.txt | grep  ", ${resultStatus}$" || echo "no test found for patient with id ${id} " ;;

		E) break ;;
		*) echo "invalid option...chose again" ;;
		esac
		done
	

elif [ $operation -eq 3 ]
then
	ubnormal
elif [ $operation -eq 4 ]
then
	avg
elif [ $operation -eq 5 ]
then
	printf "enter patient id:\n"
	read -r id
	check "$id"

	printf "enter test name to update:\n"
        read -r testName
        printf "enter test date to update:\n"
        read -r testD
        printf "enter test  result to update:\n"
        read -r testfl
        printf "enter test unit to update:\n"
        read -r testun
        printf "enter test status to update:\n"
        read -r teststat
        
        

	chec=$(grep "^${id}: ${testName}, ${testD}, ${testfl}, ${testun}, ${teststat}" midecalRecord.txt )


	if [ -n "$chec" ]; then
	printf "the record: $chec\n"
	printf "enter the new test result :\n"
	read -r answer

	printf "do you want to update the date? (Y/N):\n"
	read -r UpdateDate
	if [[ "$UpdateDate" == "Y" || "$UpdateDate" == "y" ]]; then
	printf "enter the new date for test (YYYY-MM):\n"
	read -r newDate
	else
		newDate=$(echo "$chec" | cut -d ',' -f2 | tr -d ' ')
	fi

	printf "do you want to update the unit? (Y/N):\n"
        read -r UpdateUnit
        if [[ "$UpdateUnit" == "Y" || "$UpdateUnit" == "y" ]]; then
        printf "enter the new unit for test:\n"
        read -r newUnit
        else
                newUnit=$(echo "$chec" | cut -d ',' -f4 | tr -d ' ')
        fi

	printf "do you want to update the status? (Y/N):\n"
        read -r updateStatus
        if [[ "$updateStatus" == "Y" || "$updateStatus" == "y" ]]; then
        printf "enter the new status for test (pending, completed, reviewed):\n"
        read -r newStatus
        else
                newStatus=$(echo "$chec" | cut -d ',' -f5 | tr -d ' ')
        fi

	newRecord="${id}: ${testName}, ${newDate}, ${answer}, ${newUnit}, ${newStatus}"

	tmfile=$(mktemp)
	grep -v "^${id}: ${testName}," midecalRecord.txt > "$tmfile"
	echo "$newRecord" >> "$tmfile"
	mv "$tmfile" midecalRecord.txt

	printf "the test record have been updated to:\n $newRecord\n\n"
	else
	printf "no record found for patient id ${id} and test name ${testNamr}\n\n"
	fi
elif [ $operation -eq 6 ]
then
	printf "enter patiant id cosisit of 7 digit to delete:\n"
        read id
        check "$id"

        printf "enter test name to delete:\n"
        read testName
        printf "enter test date to update:\n"
        read -r testD
        printf "enter test  result to update:\n"
        read -r testfl
        printf "enter test unit to update:\n"
        read -r testun
        printf "enter test status to update:\n"
        read -r teststat
        
        
	
	tmfile=$(mktemp)

	grep -v "^${id}: ${testName}, ${testD}, ${testfl}, ${testun}, ${teststat}" midecalRecord.txt > "$tmfile"
	mv "$tmfile" midecalRecord.txt
	printf "the test record deleted \n\n"

elif [ $operation -eq 7 ]
then
	exit 1
else
	echo "invalid operation....please try again"
	printf "\n"
fi
}


while true
do
menu
done
