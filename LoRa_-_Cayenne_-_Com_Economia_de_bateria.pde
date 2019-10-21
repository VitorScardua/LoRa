/*  
 *  ------ Comunicação LoRa para integração com Cayenne -------- 
 *  
 *  Explanation: Esse programa é desenvolvido para enviar
 *  pacotes com confirmação do Device Libelium para a integração 
 *  Cayenne de forma que deva enviar o sinal de GPS e 2 contadores,
 *  sendo um com contagem de pacotes criados para tentar enviar 
 *  e outro com a quantidade de pacotes que falharam no envio.
 *  
 *  Programa com Economia de Bateria, onde o Device manda por
 *  1 minuto dados e hiberna por 10 minutos.
 *  
 *  Obs: Programa adaptado do programa de configuração da Libelium 
 *  
 *  
 *  Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L. 
 *  http://www.libelium.com 
 */
 

#include <WaspLoRaWAN.h>
#include <WaspGPS.h>

#define LPP_GPS 136 // 3 bytes de dados para Lat ,Long e alt
#define LPP_CONTADOR 101 // 2 bytes de dados

// Data Size
#define LPP_GPS_SIZE 11
#define LPP_CONTADOR_SIZE 11

// Define o tempo de espera para tentar conectar o GPS
// definido em segundos (60sec = 1minutes)
#define TIMEOUT 60

// define a variavel de estatos do GPS
bool status;

GPS gps();

// Define socket que será usado
//////////////////////////////////////////////
uint8_t socket = SOCKET0;
//////////////////////////////////////////////

// Define parametros do Device e Back-End
////////////////////////////////////////////////////////////
char DEVICE_EUI[]  = "0004A30B0022C7A4";
char DEVICE_ADDR[] = "2601122C";
char NWK_SESSION_KEY[] = "81FE2245798C804152110AA19655D447";
char APP_SESSION_KEY[] = "35494C61F461E2720A92278832079652";
////////////////////////////////////////////////////////////

// Define a porta usada no Back-End: de 1 até 223
uint8_t PORT = 20;

// variáveis
uint8_t error;
int Ctotal = 0;
int Cerro = 0;
float Cporcento=0;

void setup() 
{
  USB.ON();
  USB.println(F("LoRaWAN - Envio de pacote para a integração Cayenne\n"));


  USB.println(F("------------------------------------"));
  USB.println(F("Configurando Modulo"));
  USB.println(F("------------------------------------\n"));


  //////////////////////////////////////////////
  // 1. Ativa o Socket
  //////////////////////////////////////////////

  error = LoRaWAN.ON(socket); //Aciona o socket

  // Verifica o Status
  if( error == 0 ) 
  {
    USB.println(F("1. Switch ON OK"));     
  }
  else 
  {
    USB.print(F("1. Switch ON error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 2. Define o Data Rate
  //////////////////////////////////////////////

//    LoRaWAN US or AU:                             //
//                                                  //
//    0: SF = 10, BW = 125 kHz, BitRate =   980 bps //
//    1: SF =  9, BW = 125 kHz, BitRate =  1760 bps //
//    2: SF =  8, BW = 125 kHz, BitRate =  3125 bps //
//    3: SF =  7, BW = 125 kHz, BitRate =  5470 bps //
    
  error = LoRaWAN.setDataRate(3); //de 0 a 3 

  // Verifica o Status
  if( error == 0 ) 
  {
    USB.println(F("2. Data rate set OK")); 
    LoRaWAN.setADR("off");   // Desativa o Data Rate Adaptativo  
  }
  else 
  {
    USB.print(F("2. Data rate set error= ")); 
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 3. Define a Potência de envio do Device
  //////////////////////////////////////////////

 
//    5:  20 dBm  //
//    6:  18 dBm  //
//    7:  16 dBm  //
//    8:  14 dBm  //
//    9:  12 dBm  //
//    10: 10 dBm  //

error = LoRaWAN.setPower(5); // Define valor da potência de 5 a 10

  // Verifica o status 
  if( error == 0 ) 
  {
    USB.println(F("2. Power level set OK"));     
  }
  else 
  {
    USB.print(F("2. Power level set error = ")); 
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 3. Configura o EUI do Device
  //////////////////////////////////////////////

  error = LoRaWAN.setDeviceEUI(DEVICE_EUI);

  // Verifica Status
  if( error == 0 ) 
  {
    USB.println(F("3. Device EUI set OK"));     
  }
  else 
  {
    USB.print(F("3. Device EUI set error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 4. Configura Endereço do Device
  //////////////////////////////////////////////

  error = LoRaWAN.setDeviceAddr(DEVICE_ADDR);

  // Verifica Status
  if( error == 0 ) 
  {
    USB.println(F("4. Device address set OK"));     
  }
  else 
  {
    USB.print(F("4. Device address set error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 5. Configura o Network Session
  //////////////////////////////////////////////

  error = LoRaWAN.setNwkSessionKey(NWK_SESSION_KEY);

  // Verifica Status
  if( error == 0 ) 
  {
    USB.println(F("5. Network Session Key set OK"));     
  }
  else 
  {
    USB.print(F("5. Network Session Key set error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 6. Configura o Application Key
  //////////////////////////////////////////////

  error = LoRaWAN.setAppSessionKey(APP_SESSION_KEY);

  // Verifica Status
  if( error == 0 ) 
  {
    USB.println(F("6. Application Session Key set OK"));     
  }
  else 
  {
    USB.print(F("6. Application Session Key set error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 7. Para 900 MHz verifica os 8 canais do gateway 
  // e desabilita os sem permissão
  //////////////////////////////////////////////

  for (int ch = 8; ch <= 64; ch++)
  {
    error = LoRaWAN.setChannelStatus(ch, "off");

    // Verifica status de cada canal
    if( error == 0 )
    {
      USB.println(F("7. Channel status set OK")); 
    }
    else
    {
      USB.print(F("7. Channel status set error = ")); 
      USB.println(error, DEC);
    }
  }

  //////////////////////////////////////////////
  // 8. Salva a Configuração
  //////////////////////////////////////////////

  error = LoRaWAN.saveConfig();

  // Verifica Status
  if( error == 0 ) 
  {
    USB.println(F("8. Save configuration OK"));     
  }
  else 
  {
    USB.print(F("8. Save configuration error = ")); 
    USB.println(error, DEC);
  }


  USB.println(F("\n------------------------------------"));
  USB.println(F("Modulo configurado"));
  USB.println(F("------------------------------------\n"));

  LoRaWAN.getDeviceEUI();
  USB.print(F("Device EUI: "));
  USB.println(LoRaWAN._devEUI);  

  LoRaWAN.getDeviceAddr();
  USB.print(F("Device Address: "));
  USB.println(LoRaWAN._devAddr);  

  USB.println();  
}

  //////////////////////////////////////////////
  // Configuração da Classe Cayenne
  //////////////////////////////////////////////

class CayenneLPP {
public:
CayenneLPP(uint8_t size);
~CayenneLPP();

void reset(void);
uint8_t getSize(void);
uint8_t* getBuffer(void);
uint8_t copy(uint8_t* buffer);

uint8_t addGPS(uint8_t channel, float latitude, float longitude, float meters); // Delcara a função GPS
uint8_t addContador(uint8_t channel, int Contador); // Declara a função contador


private:
uint8_t *buffer;
uint8_t maxsize;
uint8_t cursor;

};

CayenneLPP::CayenneLPP(uint8_t size) : maxsize(size)
//Inicializa o bufer do payload com o maior tamanho
{
buffer = (uint8_t*) malloc(size);
cursor = 0;
}

CayenneLPP::~CayenneLPP(void)
{
free(buffer);
}

void CayenneLPP::reset(void)
//Reseta o payload, precisa ser chamado antes de criar um novo payload
{
cursor = 0;
}

uint8_t CayenneLPP::getSize(void)
//Retorna o tamanho atual do payload
{
return cursor;
}

uint8_t* CayenneLPP::getBuffer(void)
//Retorna o Buffer do payload
{
return buffer;
}

uint8_t CayenneLPP::copy(uint8_t* dst)
{
memcpy(dst, buffer, cursor);
return cursor;
}

uint8_t CayenneLPP::addGPS(uint8_t channel, float latitude, float longitude, float meters) //Função para criar payload para os dados do sensor GPS
{
    if ((cursor + LPP_GPS_SIZE) > maxsize) {
        return 0;
    }
    int32_t lat = latitude * 10000;
    int32_t lon = longitude * 10000;
    int32_t alt = meters * 100;

    buffer[cursor++] = channel; //Guarda o numero do canal destinado a GPS no payload
    buffer[cursor++] = LPP_GPS; //Guarda o código do GPS (código definido pelo Cayenne para que o mesmo perceba que os dados seguintes se referem a um GPS)

    //Guarda os Bytes de latitude, longitude e altura
    buffer[cursor++] = lat >> 16; //Guarda os Bytes da LAT
    buffer[cursor++] = lat >> 8; 
    buffer[cursor++] = lat; 
    buffer[cursor++] = lon >> 16; //Guarda os Bytes da LAT
    buffer[cursor++] = lon >> 8; 
    buffer[cursor++] = lon; 
    buffer[cursor++] = alt >> 16; //Guarda os Bytes da LAT
    buffer[cursor++] = alt >> 8;
    buffer[cursor++] = alt;

    return cursor;
}

uint8_t CayenneLPP::addContador(uint8_t channel, int Contador)//Função para criar payload para os dados de um Contador
{
  if ((cursor + LPP_CONTADOR_SIZE) > maxsize) {
        return 0;
  }
  buffer[cursor++] = channel; //Guarda o numero do canal destinado a GPS no payload
  buffer[cursor++] = LPP_CONTADOR; //Guarda o código do Contador (código definido pelo Cayenne para que o mesmo perceba que os dados seguintes se referem ao dado)
  //***OBS: Neste caso a função está usando o código do luximetro do cayenne pois é o que melhor representa o contador, visto que o Cayenne não possui código para contador) 
  
  buffer[cursor++] = Contador >> 8; //Guarda valor do contador
  buffer[cursor++] = Contador;

  return cursor;
}


CayenneLPP Payload(200);

  //////////////////////////////////////////////
  // Inicio do Programa
  //////////////////////////////////////////////

void loop() 
{
    RTC.ON(); //Inicializa o Tempo Real
    GPS.ON(); //Inicializa o GPS
    
    //////////////////////////////////////////////////////
    // Define tempo em que o Device irá ficar comunicando
    /////////////////////////////////////////////////////
    USB.println(F("\n++++++++++++++ Alarm 1 - OFFSET MODE ++++++++++++++++"));
    USB.println(RTC.getTime());
    // Alarme definido poara 1 minuto
    RTC.setAlarm1("00:00:01:00",RTC_OFFSET,RTC_ALM1_MODE2); //Define por quanto tempo o Device irá tentar enviar pacote
    
    volta: // Flag para retorno da função enquanto alarme não for ativado
    
    ///////////////////////////////////////////////////
    // Espera GPS Comunicar
    ///////////////////////////////////////////////////
    status = GPS.waitForSignal(TIMEOUT); //Verifica Status do TimeOut do GPS
  
    if( status == true ) // Verifica se GPS conectou
    {
      USB.println(F("\n----------------------"));
      USB.println(F("Connected"));
      USB.println(F("----------------------"));
  
          
      //////////////////////////////////////////////
      // Cria o Payload
      //////////////////////////////////////////////
      USB.println(F("Criando Payload"));
      int size = 0;
      Payload.reset(); //Reseta Payload
  
      float Alt = atoi(GPS.getAltitude()); //Define Variável do GPS
  
      //////////////////////////////////////////////
      // Montando o Payload
      //////////////////////////////////////////////
      Ctotal++; //Contador de Pacotes Criados e que tentaram ser enviados
  
      size = Payload.addGPS(20,GPS.convert2Degrees(GPS.latitude, GPS.NS_indicator),GPS.convert2Degrees(GPS.longitude, GPS.EW_indicator),Alt); //Cria Payload para GPS com Canal 20 GPS, canal 0 Temperatura
  
      Payload.addContador(0,Ctotal); //Adiciona o contador de pacotes totais ao payload
      Payload.addContador(1,Cerro); //Adiciona o contador de pacotes falhos ao payload
  
      
      //////////////////////////////////////////////
      // Ativa o Socket
      //////////////////////////////////////////////
      
      // Configurando de novo pois o Device tende a muda-lo automaticamente
    
      error = LoRaWAN.ON(socket); //Aciona o socket
    
      // Verifica o Status
      if( error == 0 ) 
      {
        USB.println(F(" Switch ON OK"));     
      }
      else 
      {
        USB.print(F(" Switch ON error = ")); 
        USB.println(error, DEC);
      }
  
      
      //////////////////////////////////////////////
      //  Define o Data Rate
      //////////////////////////////////////////////
      
      error = LoRaWAN.setDataRate(3);
      LoRaWAN.setADR("off");
      
      // Check status
      if( error == 0 )
      {
      USB.println(F(" Data rate set OK"));
      }
      else
      {
      USB.print(F(" Data rate set error = "));
      USB.println(error, DEC);
      } 
      //////////////////////////////////////////////
      //  Verifica conexão para envio de pacote
      //////////////////////////////////////////////
      
      error = LoRaWAN.joinABP();
      
      // Check status
      if( error == 0 ) 
      {
      USB.println(F(" Join network OK")); 
      
      //////////////////////////////////////////////
      //  Envia Pacote
      //////////////////////////////////////////////
      
      error = LoRaWAN.sendConfirmed( PORT,Payload.getBuffer(), Payload.getSize()); //Envia Payload e espera por ACK de confirmação de recebimento
      
      // Mensagens de erro:
      /*
      * '6' : Modulo não conectou a rede
      * '5' : Erro de envio
      * '4' : Erro com o tamanho do payload  
      * '2' : Módulo não responde
      * '1' : Cominucação do módulo com erro 
      */
      // Verifica Status
      if( error == 0 ) 
      {
      USB.println(F("Send confirmed packet OK")); 
      if (LoRaWAN._dataReceived == true)
      { 
      USB.print(F(" There's data on port number "));
      USB.print(LoRaWAN._port,DEC);
      USB.print(F(".\r\n Data: "));
      USB.println(LoRaWAN._data);
      }
      }
      else 
      {
      USB.print(F("Send confirmed packet error = ")); 
      USB.println(error, DEC);
      Cerro++; // Soma contador de erro caso haja erro
      goto volta; // Retorna ao começo do programa sem acionar alarme
      } 
      }
      else 
      {
      USB.print(F("2. Join network error = ")); 
      USB.println(error, DEC);
      }
      
      
      //////////////////////////////////////////////
      // Switch off
      //////////////////////////////////////////////
      
      error = LoRaWAN.OFF(socket);
      
      // Check status
      if( error == 0 ) 
      {
      USB.println(F("5. Switch OFF OK")); 
      }
      else 
      {
      USB.print(F("5. Switch OFF error = ")); 
      USB.println(error, DEC);
      }
      
      if (intFlag & RTC_INT) // Verifica se o tempo de 1 minuto já estorou
      {
        /////////////////////////////////////////////////////
        // Configura tempo de DeepSleep (economia de bateria)
        /////////////////////////////////////////////////////
        
        // Para consumir bateria usa-se o DeepSleep
        // Depois de 10 minutos o Waspmote Ativa
        USB.println(F("Enter deep sleep mode to wait for sensors heating time..."));
        PWR.deepSleep("00:00:10:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON); //Define tempo que o Device irá hibernar
        USB.ON();
        USB.println(F("wake up!!\r\n"));
        intFlag &= ~(RTC_INT); // Limpa a flag de alarme
      }
      else{  
      delay(300);
      goto volta; // Retorna ao começo antes do ajuste de alarme
      }
   }
   else
   {
     USB.println(F("\n----------------------"));
     USB.println(F("GPS TIMEOUT. NOT connected"));
     USB.println(F("----------------------"));
   }
}
