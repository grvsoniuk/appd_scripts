VERSION="4.2.10.0"
if [ "$VERSION" \< "4.3" ]; then
	echo "less then 4.3"
else
	echo "greater or equals to 4.3"
fi