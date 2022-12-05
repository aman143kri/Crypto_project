# Run using sudo
echo "Welcome to the Fully Functional CA tool"

root_ca_flag=0
intermediate_ca_flag=0
revoke_ca_flag=0

root_ca(){
	if [ $root_ca_flag -eq 0 ]; then
        mkdir /root/ca
        echo "created ca directory \n"
        cd /root/ca
        mkdir certs crl newcerts private
        chmod 700 private
        touch index.txt
        echo 1000 > serial
        sudo wget https://raw.githubusercontent.com/aman143kri/Crypto_project/main/openssl.cnf -O /root/ca/openssl.cnf
        echo "Now the privatekey will be generated for root ca \n"
        openssl genrsa -aes256 -out private/ca.key.pem 4096
        chmod 400 private/ca.key.pem
        echo "Creating Root Certificate \n"
        openssl req -config openssl.cnf \
      -key private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out certs/ca.cert.pem
        chmod 444 certs/ca.cert.pem  
        openssl x509 -noout -text -in certs/ca.cert.pem
        openssl x509 -noout -text -in certs/ca.cert.pem | grep -B10 -A10 Issuer 
        root_ca_flag=1
        else 
        echo "Root CA already created \n"
        fi
}

intermediate_ca(){
	if [ $intermediate_ca_flag -eq 0 ]; then	
        echo "Creating directory \n"
        mkdir /root/ca/intermediate
        cd /root/ca/intermediate
        mkdir certs crl csr newcerts private
        chmod 700 private
        touch index.txt
        echo 1000 > serial
        echo 1000 > /root/ca/intermediate/crlnumber
        echo "getting config from github \n"
        sudo wget https://raw.githubusercontent.com/aman143kri/Crypto_project/main/i_openssl.cnf -O /root/ca/intermediate/openssl.cnf
        echo "Creating the intermediate key \n"
        openssl genrsa -aes256 \
      -out /root/ca/intermediate/private/intermediate.key.pem 4096

        chmod 400 /root/ca/intermediate/private/intermediate.key.pem

        cd /root/ca
        #echo "Use the intermediate key to create a certificate signing request \n"
        #openssl genrsa -aes256 \
      #-out intermediate/private/intermediate.key.pem 4096

#       chmod 400 /root/ca/intermediate/private/intermediate.key.pem

         echo "Use the intermediate key to create a certificate signing request \n"


        openssl req -config /root/ca/intermediate/openssl.cnf -new -sha256 \
      -key /root/ca/intermediate/private/intermediate.key.pem \
      -out /root/ca/intermediate/csr/intermediate.csr.pem

        openssl ca -config /root/ca/openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in /root/ca/intermediate/csr/intermediate.csr.pem \
      -out /root/ca/intermediate/certs/intermediate.cert.pem

        chmod 444 /root/ca/intermediate/certs/intermediate.cert.pem


        cat /root/ca/intermediate/certs/intermediate.cert.pem \
      /root/ca/certs/ca.cert.pem > /root/ca/intermediate/certs/ca-chain.cert.pem

        chmod 444 intermediate/certs/ca-chain.cert.pem
        intermediate_ca_flag=1
        else
        echo "intermediate CA already created \n"
        fi
}


sign_certificate(){

        echo  "Generate certificate for certificate \n"
        openssl genrsa -out /root/ca/intermediate/private/$domain_name.key.pem 2048

        chmod 400 /root/ca/intermediate/private/$domain_name.key.pem

        echo "Using the private key to create a certificate signing request (CSR) \n"
        openssl req -config /root/ca/intermediate/openssl.cnf \
      -key /root/ca/intermediate/private/$domain_name.key.pem \
      -new -sha256 -out /root/ca/intermediate/csr/$domain_name.csr.pem
	
        echo "Using the intermediate CA to sign the CSR \n"
        openssl ca -config /root/ca/intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in /root/ca/intermediate/csr/$domain_name.csr.pem \
      -out /root/ca/intermediate/certs/$domain_name.cert.pem


        chmod 444 /root/ca/intermediate/certs/$domain_name.cert.pem

}

update_Certificate(){
        sudo apt-get install -y ca-certificates
        sudo cp /root/ca/certs/ca.cert.pem /usr/local/share/ca-certificates/myCA$domain_name.crt
        sudo update-ca-certificates
        service apache2 restart
}
check_Certificate(){
        echo "Checking if ssl is working fine \n"
        openssl verify -CAfile /root/ca/intermediate/certs/ca-chain.cert.pem \
              /root/ca/intermediate/certs/$domain_name.cert.pem >> check_result
        if [["$check_result" =~ .*"ok".*]];then
                echo "certificate is valid \n"
        fi
}

crl_create(){
openssl ca -config /root/ca/intermediate/openssl.cnf \
      -gencrl -out intermediate/crl/intermediate.crl.pem
}

revoke_certificate(){
crl_create
echo "Checking the contents of the crl using openssl crl tool \n"
openssl crl -in intermediate/crl/intermediate.crl.pem -noout -text
openssl ca -config /root/ca/intermediate/openssl.cnf \
      -revoke /root/ca/intermediate/certs/$domain_name.cert.pem
cat /root/ca/intermediate/index.txt | grep "R"
crl_create
}


reissue_certificate(){
        openssl ca -config /root/ca/intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in /root/ca/intermediate/csr/$domain_name.csr.pem \
      -out /root/ca/intermediate/certs/$domain_name.cert.pem
}


x=1; 
y=1



while [ $x -ge 0 ]
do 
        echo "Press 1 For Automatic"
        echo "Press 2 For Manual"
        read choosen_method
        echo $choosen_method
        if [ $choosen_method -eq 1 ]; then
                echo "You have chose Automatic mode \n"
                echo "Enter the domain name \n"
		read domain_name
                echo "This will create your root certificate, intermediate certificate and certificate for your browser"
                root_ca
                echo "root_ca created"
                intermediate_ca
                echo "intermediate ca created"
                sign_certificate
                echo "certificate signed"
                update_Certificate
                echo "certificated updated"
        elif [ $choosen_method -eq 2 ]; then
        	echo "Enter the domain name \n"
		read domain_name
                while [ $y -ge 0 ]
		do 
                echo "You have choosen manual mode"
                echo "Press 1 for generating root ca certificate \n"
                echo "Press 2 for generating intermediate certificate \n"
                echo "Press 3 for signing the webserver \n"
                echo "Press 4 for revoking the webserver \n"
                echo "Press 5 for reissuing the webserver \n"
                echo "Press 6 for updating the certificates locally \n"
                echo "Press 7 for exit \n"
                read manual_input
                if [ $manual_input -eq 1 ]; then
                	if [ $root_ca_flag -eq 1 ]; then
                		echo "root ca already generated"
                	else 
                		echo "generating root ca"
                		root_ca
                	fi
                elif [ $manual_input -eq 2 ]; then
                	if [ $intermediate_ca_flag -eq 1 ]; then
                		echo "intermediate ca already generated"
                	else 
                		echo "generating intermediate ca"
                		intermediate_ca
                	fi
                elif [ $manual_input -eq 3 ]; then
      			 echo "Enter the domain name \n"
			 read domain_name
			 sign_certificate          
                elif [ $manual_input -eq 4 ]; then	
               		revoke_certificate
               	elif [ $manual_input -eq 5 ]; then
               		reissue_certificate
               	elif [ $manual_input -eq 6 ]; then
               		update_Certificate
 		elif [ $manual_input -eq 7 ]; then
 			y=-1
 		else 
 			echo "wrong input \n"
 			y=-1
 		fi
 	done
        else
                echo "wrong input, Exiting \n"
                x=-1;
        fi
done
      
