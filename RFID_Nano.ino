#include <SPI.h>
#include <MFRC522.h>
#include <Servo.h>

#define RC522_SS_PIN  10  // The Arduino Nano pin connected to RC522's SS pin
#define RC522_RST_PIN 5   // The Arduino Nano pin connected to RC522's RST pin

MFRC522 rfid(RC522_SS_PIN, RC522_RST_PIN);

byte authorizedUID[4] = {0x62, 0x5F, 0x8B, 0x51};

Servo servo;

const int buzzer = 8; //buzzer to arduino pin 9

void setup() {
  Serial.begin(9600);
  SPI.begin(); // init SPI bus
  rfid.PCD_Init(); // init MFRC522

  pinMode(A0, OUTPUT);
  digitalWrite(A0, LOW);
  pinMode(A1, OUTPUT);
  digitalWrite(A1, LOW);

  servo.attach(9);
  servo.write(0);

  pinMode(buzzer, OUTPUT); // Set buzzer - pin 9 as an output

  Serial.println("Tap RFID/NFC Tag on reader");
}

void loop() {
  if (rfid.PICC_IsNewCardPresent()) { // new tag is available
    if (rfid.PICC_ReadCardSerial()) { // NUID has been readed
      MFRC522::PICC_Type piccType = rfid.PICC_GetType(rfid.uid.sak);

      if (rfid.uid.uidByte[0] == authorizedUID[0] &&
          rfid.uid.uidByte[1] == authorizedUID[1] &&
          rfid.uid.uidByte[2] == authorizedUID[2] &&
          rfid.uid.uidByte[3] == authorizedUID[3] ){
        
        Serial.println("Authorized Tag");        
        digitalWrite(A1, HIGH);
        servo.write(90);
        
        for(int i=0; i<=2; i++){
          tone(buzzer, 800); // Send 500Hz sound signal...
          delay(100);         // ...for 1 sec
          noTone(buzzer);     // Stop sound...
          delay(100);         // ...for 1sec
        }

        digitalWrite(A1, LOW);

        delay(5000);

        servo.write(0);
      }
      else
      {
        Serial.print("Unauthorized Tag with UID:");
        for (int i = 0; i < rfid.uid.size; i++) {
          Serial.print(rfid.uid.uidByte[i] < 0x10 ? " 0" : " ");
          Serial.print(rfid.uid.uidByte[i], HEX);
        }
        
        Serial.println();
        digitalWrite(A0, HIGH);
        
        tone(buzzer, 300); // Send 300Hz sound signal...
        delay(800);         // ...for 1 sec
        noTone(buzzer);     // Stop sound...

        digitalWrite(A0, LOW);
        servo.write(0);
      }

      rfid.PICC_HaltA(); // halt PICC
      rfid.PCD_StopCrypto1(); // stop encryption on PCD
    }
  }
}
