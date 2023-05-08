
/*  
 *  ------ Comunicação LoRa para integração com Cayenne -------- 
 *  
 *  Explanation: Esse programa é desenvolvido para enviar
 *  pacotes com confirmação do Device Libelium para a integração 
 *  Cayenne de forma que deva enviar Velocidade e direção do vento,
 *  pressão, humidade, temperatura, luminosidade, dados do pluviometro
 *  e 2 contadores, sendo um com contagem de pacotes criados para tentar enviar 
 *  e outro com a quantidade de pacotes que falharam no envio.
 *  
 *  Obs: Programa adaptado do programa de configuração da Libelium 
 *  
 *  
 *  Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L. 
 *  http://www.libelium.com 
 */
 

#include <WaspLoRaWAN.h>
#include <WaspGPS.h>
#include <WaspSensorAgr_v30.h>

#define LPP_GPS 136 // 3 bytes lon/lat 0.0001 °, 3 bytes alt 0.01m
#define LPP_LUMINOSITY 101 // 2 bytes, 1 lux unsigned
#define LPP_TEMPERATURE 103 // 2 bytes, 0.1°C signed
#define LPP_RELATIVE_HUMIDITY 104// 1 byte, 0.5% unsigned
#define LPP_BAROMETRIC_PRESSURE 115// 2 bytes 0.1 hPa Unsigned
#define LPP_ANALOG_INPUT 2// 2 bytes, 0.01 signed
#define LPP_CONTADOR 101 // 2 bytes, 0.5% unsigned
#define LPP_ANALOG_INPUT  2       // 2 bytes, 0.01 signed

// Data ID + Data Type + Data Size
#define LPP_GPS_SIZE 11
#define LPP_LUMINOSITY_SIZE 4
#define LPP_TEMPERATURE_SIZE 4
#define LPP_RELATIVE_HUMIDITY_SIZE 3
#define LPP_BAROMETRIC_PRESSURE_SIZE 4
#define LPP_ANALOG_INPUT_SIZE 4
#define LPP_CONTADOR_SIZE 11
#define LPP_ANALOG_INPUT_SIZE 4

// Define o tempo de espera para tentar conectar o GPS
// definido em segundos (60sec = 1minutes)
#define TIMEOUT 60

// define a variavel de estatos do GPS
bool status;

// Define socket que será usado
//////////////////////////////////////////////
uint8_t socket = SOCKET0;
//////////////////////////////////////////////

//// Define parametros do Device e Back-End
//////////////////////////////////////////////////////////////
//char DEVICE_EUI[]  = "659437450ca07f40";
//char DEVICE_ADDR[] = "00e8d32b";
//char NWK_SESSION_KEY[] = "7d92b4d96ec43fd1011dd6e2f03a962f";
//char APP_SESSION_KEY[] = "8307e9a0f51d606ef62b79a0f51778a5";
//////////////////////////////////////////////////////////////

// Define parametros do Device e Back-End PARAMETROS DE TESTE
////////////////////////////////////////////////////////////
char DEVICE_EUI[]  = "62504ab3f559d469";//
char DEVICE_ADDR[] = "008ec8c1";//
char NWK_SESSION_KEY[] = "240df2e7268a9e47b3e32d96d3059d02";//
char APP_SESSION_KEY[] = "7886fbb930f50dbaaf4809cecd80e47e";//
////////////////////////////////////////////////////////////


// Define a porta usada no Back-End: de 1 até 223
uint8_t PORT = 13;

// Variáveis
uint8_t error;
weatherStationClass weather;
uint8_t pendingPulses;
uint16_t Ctotal = 0;
uint16_t Cerro = 0;
float bat = 0;
float solar = 0;
radiationClass radSensor;
float radiation,valor;

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
    //LoRaWAN.setADR("off");   // Desativa o Data Rate Adaptativo  
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
      //USB.println(F("7. Channel status set OK")); 
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

  Agriculture.ON();  // Aciona os sensores do Modulo agricultura
}


class CayenneLPP {
  public:
  CayenneLPP(uint8_t size);
  ~CayenneLPP();
  
  void reset(void);
  uint8_t getSize(void);
  uint8_t* getBuffer(void);
  uint8_t copy(uint8_t* buffer);
  
  uint8_t addLuminosity(uint8_t channel, uint16_t lux); // Define a Função da luminosidade
  uint8_t addTemperature(uint8_t channel, float celsius); // Define a Função da temperatura
  uint8_t addRelativeHumidity(uint8_t channel, float rh); // Define a Função da humidade
  uint8_t addBarometricPressure(uint8_t channel, float hpa); // Define a Função do barometro
  uint8_t addWeatherStation(uint8_t channel, float value); // Define a Função de dados do vento e pluviometro
  uint8_t addContador(uint8_t channel, int Contador); // Define a Função do contador
  uint8_t addBateria(uint8_t channel, float value); //Valor da bateria
  uint8_t addRadiacao(uint8_t channel, float valor); // Define a Função de dados de radiação (dividido por 10 o valor)
  
  
  private:
  uint8_t *buffer;
  uint8_t maxsize;
  uint8_t cursor;
  
  };
  
CayenneLPP::CayenneLPP(uint8_t size) : maxsize(size)
//Initialize the payload buffer with the given maximum size.
{
  buffer = (uint8_t*) malloc(size);
  cursor = 0;
}

CayenneLPP::~CayenneLPP(void)
{
  free(buffer);
}

void CayenneLPP::reset(void)
//Reset the payload, to call before building a frame payload
{
  cursor = 0;
}

uint8_t CayenneLPP::getSize(void)
//Returns the current size of the payload
{
  return cursor;
}
  
uint8_t* CayenneLPP::getBuffer(void)
  //Return the payload buffer
{
  return buffer;
}

uint8_t CayenneLPP::copy(uint8_t* dst)
{
  memcpy(dst, buffer, cursor);
  return cursor;
}

uint8_t CayenneLPP::addLuminosity(uint8_t channel, uint16_t lux)//Função para criar payload para os dados do sensor de luminosidade
{
    if ((cursor + LPP_LUMINOSITY_SIZE) > maxsize) {
        return 0;
    }
    buffer[cursor++] = channel; //Guarda o numero do canal destinado a luminosidade no payload
    buffer[cursor++] = LPP_LUMINOSITY; //Guarda o código da luminosidade (código definido pelo Cayenne para que o mesmo perceba que os dados seguintes se referem a luminosidade)
    buffer[cursor++] = lux >> 8; //Guarda os bytes da luminosidade
    buffer[cursor++] = lux; 

    return cursor;
}

uint8_t CayenneLPP::addTemperature(uint8_t channel, float celsius)//Função para criar payload para os dados do sensor de temperatura
{
    if ((cursor + LPP_TEMPERATURE_SIZE) > maxsize) {
        return 0;
    }
    int16_t val = celsius * 10;
    buffer[cursor++] = channel; //Guarda o numero do canal destinado a temperatura no payload
    buffer[cursor++] = LPP_TEMPERATURE; //Guarda o código da temperatura (código definido pelo Cayenne para que o mesmo perceba que os dados seguintes se referem a temperatura)
    buffer[cursor++] = val >> 8; // Guarda os bytes da temperatura
    buffer[cursor++] = val; 

    return cursor;
}

uint8_t CayenneLPP::addRelativeHumidity(uint8_t channel, float rh) //Função para criar payload para os dados do sensor de Humidade
{
    if ((cursor + LPP_RELATIVE_HUMIDITY_SIZE) > maxsize) {
        return 0;
    }
    buffer[cursor++] = channel; //Guarda o numero do canal destinado a humidade no payload
    buffer[cursor++] = LPP_RELATIVE_HUMIDITY; //Guarda o código da humidade (código definido pelo Cayenne para que o mesmo perceba que os dados seguintes se referem a humidade)
    buffer[cursor++] = rh * 2; // Guarda os bytes da temperatura

    return cursor;
}

uint8_t CayenneLPP::addBarometricPressure(uint8_t channel, float hpa) //Função para criar payload para os dados do Barometro
{
    if ((cursor + LPP_BAROMETRIC_PRESSURE_SIZE) > maxsize) {
        return 0;
    }
    int16_t val = hpa / 100;

    buffer[cursor++] = channel; //Guarda o numero do canal destinado ao barometro no payload
    buffer[cursor++] = LPP_BAROMETRIC_PRESSURE; //Guarda o código do barometro (código definido pelo Cayenne para que o mesmo perceba que os dados seguintes se referem ao barometro)
    buffer[cursor++] = val >> 8; // Guarda os bytes do barometro
    buffer[cursor++] = val; 

    return cursor;
}

uint8_t CayenneLPP::addWeatherStation(uint8_t channel, float value) //Função para criar payload para os dados do vento e pluviometro
{
    if ((cursor + LPP_ANALOG_INPUT_SIZE) > maxsize) {
        return 0;
    }

    int16_t val = value*100;
    buffer[cursor++] = channel; //Guarda o numero do canal destinado as dados de vento e pluviometro no payload
    buffer[cursor++] = LPP_ANALOG_INPUT; //Guarda o código dos dados (código definido pelo Cayenne para que o mesmo perceba que os dados seguintes se referem aos dados de vento e pluviometro)
    //***OBS: Neste caso a função está usando o código da estção meteriologica do cayenne pois é o que melhor representa os dados de vento e pluviometro, visto que o Cayenne não possui código para os mesmos) 
  
    buffer[cursor++] = val >> 8; // Guarda os bytes do vento e pluviometro
    buffer[cursor++] = val; 

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

uint8_t CayenneLPP::addBateria(uint8_t channel, float value)
{
    if ((cursor + LPP_ANALOG_INPUT_SIZE) > maxsize) {
        return 0;
    }

    int32_t val = value*100;
    buffer[cursor++] = channel; 
    buffer[cursor++] = LPP_ANALOG_INPUT; 
    buffer[cursor++] = val >> 8; 
    buffer[cursor++] = val; 

    return cursor;
}

uint8_t CayenneLPP::addRadiacao(uint8_t channel, float valor) //Função para criar payload para os dados do sensor de radiação(deve ser multiplicado por 100 o valor que aparece no cayenne)
{
    if ((cursor + LPP_BAROMETRIC_PRESSURE_SIZE) > maxsize) {
        return 0;
    }

    int32_t val = valor*10;
    buffer[cursor++] = channel; //Guarda o numero do canal destinado as dados de vento e pluviometro no payload
    buffer[cursor++] = LPP_BAROMETRIC_PRESSURE; //Guarda o código dos dados (código definido pelo Cayenne para que o mesmo perceba que os dados seguintes se referem aos dados de vento e pluviometro)
    //***OBS: Neste caso a função está usando o código da estção meteriologica do cayenne pois é o que melhor representa os dados de vento e pluviometro, visto que o Cayenne não possui código para os mesmos) 
    buffer[cursor++] = val >> 8;
    buffer[cursor++] = val; 

    return cursor;
}

CayenneLPP Payload(1000);

void loop() 
{
    
    //////////////////////////////////////////////
    // Cria o Payload
    //////////////////////////////////////////////
    USB.println(F("Criando Payload"));
    int size = 0;
    Payload.reset(); //Reseta Payload

    Ctotal ++;

    //////////////////////////////////////////////
    // Montando o Payload
    //////////////////////////////////////////////

//    USB.print("Luz: ");
//    USB.println(Agriculture.getLuxes(OUTDOOR));
//    USB.print("Temp: ");
//    USB.println(Agriculture.getTemperature());
//    USB.print("Humi: ");
//    USB.println(Agriculture.getHumidity());
//    USB.print("Press: ");
//    USB.println(Agriculture.getPressure());
//    USB.print("Vel Vent: ");
//    USB.println(weather.readAnemometer());
    
    size = Payload.addLuminosity(0, Agriculture.getLuxes(OUTDOOR)); //Cria Payload para luximetro com Canal 0; INDOOR ou OUTDOOR, dependendo da funçaõ desejada


    Payload.addTemperature(1, Agriculture.getTemperature()); //Cria Payload para temperatura com Canal 1
    Payload.addRelativeHumidity(2, Agriculture.getHumidity()); //Cria Payload para humidade com Canal 2
    Payload.addBarometricPressure(3, Agriculture.getPressure()); //Cria Payload para barometro com Canal 3
    Payload.addWeatherStation(4, weather.readAnemometer()); //Cria Payload para Velocidade do vento com Canal 4

    switch(weather.readVaneDirection()) //Cria Payload para direção do vento com Canal 5
    {
      case  SENS_AGR_VANE_N   :  Payload.addWeatherStation(5,1); // Caso seja Norte(N) manda valor 1
                                 USB.println("Norte");
                                 break;
      case  SENS_AGR_VANE_NNE :  Payload.addWeatherStation(5,2); // Caso seja Nor-Nordeste(NNE) valor 2
                                 USB.println("Nor-Nordeste"); 
                                 break;  
      case  SENS_AGR_VANE_NE  :  Payload.addWeatherStation(5,3); // Caso seja Nordeste(NE) valor 3
                                 USB.println("Nordeste");
                                 break;    
      case  SENS_AGR_VANE_ENE :  Payload.addWeatherStation(5,4); // Caso seja lês-Nordeste(ENE) valor 4
                                 USB.println("ENE");
                                 break;      
      case  SENS_AGR_VANE_E   :  Payload.addWeatherStation(5,5); // Caso seja Leste(E) valor 5
                                 USB.println("E");
                                 break;    
      case  SENS_AGR_VANE_ESE :  Payload.addWeatherStation(5,6); // Caso seja Les-Sudeste(ESE) valor 6
                                 USB.println("ESE");
                                 break;  
      case  SENS_AGR_VANE_SE  :  Payload.addWeatherStation(5,7); // Caso seja Sudeste(SE) valor 7
                                 USB.println("SE");
                                 break;    
      case  SENS_AGR_VANE_SSE :  Payload.addWeatherStation(5,8); // Caso seja Su-Sudeste(SSE) valor 8
                                 USB.println("SSE");
                                 break;   
      case  SENS_AGR_VANE_S   :  Payload.addWeatherStation(5,9); // Caso seja Sul(S) valor 9
                                 USB.println("S");
                                 break; 
      case  SENS_AGR_VANE_SSW :  Payload.addWeatherStation(5,10); // Caso seja Su-Sudoeste(SSW) valor 10
                                 USB.println("SSW");
                                 break; 
      case  SENS_AGR_VANE_SW  :  Payload.addWeatherStation(5,11); // Caso seja Sudoeste(SW) valor 11
                                 USB.println("SW");
                                 break;  
      case  SENS_AGR_VANE_WSW :  Payload.addWeatherStation(5,12); // Caso seja Oes-Sudoeste(WSW) valor 12
                                 USB.println("WSW");
                                 break; 
      case  SENS_AGR_VANE_W   :  Payload.addWeatherStation(5,13); // Caso seja Oeste(W) valor 13
                                 USB.println("W");
                                 break;   
      case  SENS_AGR_VANE_WNW :  Payload.addWeatherStation(5,14); // Caso seja Oes-Noreoeste(WNW) valor 14
                                 USB.println("WNW");
                                 break; 
      case  SENS_AGR_VANE_NW  :  Payload.addWeatherStation(5,15); // Caso seja Noroeste(NW) valor 15
                                 USB.println("NW");
                                 break;
      case  SENS_AGR_VANE_NNW :  Payload.addWeatherStation(5,16); // Caso seja Nor-Noroeste(NNW) valor 16
                                 USB.println("NNW");
                                 break;  
      default                 :  Payload.addWeatherStation(5,0); // Caso nem um dos casos jogar valor 0 de erro
                                 USB.println("ERROU A DIREÇÃO");
                                 break;    
    }

    /////////////////////////////////////////////
    // Entra em Sleep para medição do pluviometro
    /////////////////////////////////////////////
    Agriculture.sleepAgr("00:00:00:10", RTC_ABSOLUTE, RTC_ALM1_MODE5, SENSOR_ON, SENS_AGR_PLUVIOMETER);
    
    /////////////////////////////////////////////
    //Verifica o pluviometro
    /////////////////////////////////////////////
    if( intFlag & PLV_INT)
    {
  
      pendingPulses = intArray[PLV_POS];
  
      for(int i=0 ; i<pendingPulses; i++)
      {
        // Verifica os pulsos do pluviometro
        weather.storePulse();
  
        // diminui o numero de pulsos
        intArray[PLV_POS]--;
      }
      // limpa a flag
      intFlag &= ~(PLV_INT); 
    }

//    USB.print("Plu: ");
//    USB.println(weather.readPluviometerCurrent());
//    USB.print("Total: ");
//    USB.println(Ctotal);
//    USB.print("Erro: ");
//    USB.println(Cerro);
  
    Payload.addWeatherStation(6,weather.readPluviometerCurrent()); //Cria Payload para pluviometro com Canal 6
    Payload.addContador(7,Ctotal); //Cria Payload para contador de pacotes totais com Canal 7
    Payload.addContador(8,Cerro); //Cria Payload para contador de pacotes com erro com Canal 8
    bat = PWR.getBatteryLevel(),DEC;
    Payload.addBateria(9, bat); //Cria Payload para bateria com Canal 9
    solar = PWR.getBatteryCurrent(),DEC;
    Payload.addBateria(10,solar); //Cria Payload para corrente do painel solar com Canal 10
    // Part 1: Read the solar radiation sensor 
    valor = radSensor.readRadiation();  
    //Conversion from voltage into W/m² - 0.2mV por W/m²
    radiation = valor / 0.02;
    USB.println(radiation);
    Payload.addRadiacao(11, radiation); //Cria Payload para sensor de radiação com Canal 11

//    uint8_t *pld = Payload.getBuffer();
//
//    for (unsigned char i = 0; i < Payload.getSize(); i++)
//   {
//      USB.print(pld[i], HEX);
//   }


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
      } 
      }
      else 
      {
      USB.print(F(" Join network error = ")); 
      USB.println(error, DEC);
      }
      
      
      //////////////////////////////////////////////
      // Switch off
      //////////////////////////////////////////////
      
      error = LoRaWAN.OFF(socket);
      
      // Check status
      if( error == 0 ) 
      {
      USB.println(F(" Switch OFF OK")); 
      }
      else 
      {
      USB.print(F(" Switch OFF error = ")); 
      USB.println(error, DEC);
      }
}
