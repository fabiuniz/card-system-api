curl http://Smart_Send_Device:8080/api/help 
curl http://Smart_Send_Device:8080/api/files
curl -X POST http://Smart_Send_Device:8080/api/message -H "Content-Type: application/json" -d '{"message": "Ola do terminal!"}'
#curl -o "MessageSend.apk" "http://Smart_Send_Device:8080/api/files/MessageSend.apk"
curl -X POST http://Smart_Send_Device:8080/api/upload   -H "X-File-Name: MessageSend.apk"   --data-binary "@C:\Users\Fabiano\Downloads\MessageSend.apk"

