MODEL=$1

function usage {
	echo "tests.sh MODEL [TESTS]"
	exit -2
}

function try {
	comment=$1
	log=$(echo $comment | sed 's/ /./g').log
	shift
		echo -n "$comment... "
		if "$@" >$log 2>&1
		then
			echo "OK"
		else
			echo "FAILED"
			echo "----------------- CMD ----------------"
			echo $@
			echo "----------------- LOG ----------------"
			cat  $log
			echo "--------------------------------------"
			exit -1;
		fi
	return 0;
}


test -z "$MODEL" && usage

if ! test -d "src/$MODEL"
then
	echo \"$MODEL\" is not a model
	usage
fi

if ! test -f "CLB/$MODEL/main"
then
	echo \"$MODEL\" is not compiled
	echo "  run: make $MODEL"
	exit -1;
fi

shift

if ! test -f "tests/README.md"
then
	echo \"tests\" submodule is not checked out
	exit -1
fi

if ! test -d "tests/$MODEL"
then
	echo No tests for model $MODEL.
	echo Exiting with no error.
	exit 0
fi

if test -z "$1"
then
	TESTS=$(cd tests/$MODEL; ls *.xml 2>/dev/null)
else
	echo "Running specific tests not yet implemented"
	exit -1
fi

if test -z "$TESTS"
then
	echo "No tests for model $MODEL \(WARNING: there is a directory tests/$MODEL !\)"
	echo "Exiting with error. Because I Can."
	exit -1
fi

GLOBAL="OK"
for t in $TESTS
do
	name=${t%.*}
	RESULT="FAILED"
	if try "Running \"$name\" test" CLB/$MODEL/main "tests/$MODEL/$t"
	then
		RESULT="OK"
		RES=$(cd tests/$MODEL; find -name "${name}_*")
		if ! test -z "$RES"
		then
			for r in $RES
			do
				g=tests/$MODEL/$r
				echo -n " > Checking $r... "
				if test -f "$r"
				then
					if ! test -f "$g"
					then
						echo "$g not found - this should not happen!"
						exit -123
					fi
					if diff "$r" "$g" >/dev/null 2>&1
					then
						echo "OK"
					else
						echo "Different"
						RESULT="WRONG"
					fi
				else
					echo "Not found"
					RESULT="WRONG"
				fi
			done
		fi
	fi
	if ! test "x$RESULT" == "xOK"
	then
		echo " > Test \"$name\" returned: $RESULT"
		GLOBAL="FAILED"
	fi
done

if test "x$GLOBAL" == "xOK"
then
	exit 0
else
	echo "Some tests failed"
	exit -1
fi