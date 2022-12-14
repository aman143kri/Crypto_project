# Crypto_project

A video demonstration of how the tool operates:

This is a concise demonstration of a fully functional certificate authority

It has 2 modes: 
1. Manual 
2. Automatic

* Manual Mode allows you to perform each step individually and you can choose what steps to perform 

![image](https://user-images.githubusercontent.com/42419157/205622189-90e54768-4457-4414-b3c2-b7b014436f7e.png)

* Automatic mode takes the domain as input and runs all the functions 

**Docker image that has a certificate installed for example.com**

``` bash 
docker pull aman143kri/functional_ca
```

Manual Installation (Created for linux): 
``` bash 
wget https://raw.githubusercontent.com/aman143kri/Crypto_project/main/test.sh
chmod +x test.sh 
```
Run the script as root: 
``` bash
sudo ./test.sh
```

**For seeing in browser you would need to add the intermediate/root ca into the browser. Tested on Firefox**

For docker installation:


https://user-images.githubusercontent.com/42419157/206885046-4a9741f5-62a3-4068-93ac-a801d3441497.mp4



For manual installation:

https://user-images.githubusercontent.com/42419157/205621331-15f7208a-a98e-49b9-b817-07349d69ed24.mp4



