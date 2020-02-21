
/*  
 *  ------ Comunicação LoRa para integração com Cayenne -------- 
 *  
 *  Explanation: Esse programa é desenvolvido para enviar
 *  pacotes com confirmação do Device Libelium para a integração 
 *  Cayenne de forma que deva enviar o sinal de GPS e 2 contadores,
 *  sendo um com contagem de pacotes criados para tentar enviar 
 *  e outro com a quantidade de pacotes que falharam no envio.
 *  
 *  
 *  Obs: Programa adaptado do programa de configuração da Libelium 
 *  
 *  
 *  Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L. 
 *  http://www.libelium.com 
 */
 

#include <WaspLoRaWAN.h>
#include <Waspclasses.h>

#define LPP_CONTADOR 101 // 2 bytes de dados

// Data Size
#define LPP_CONTADOR_SIZE 11


char arq[]="/cari/TESTE1.TXT"; //colocar nome do txt em relação ao teste
char pasta[]="/cari"; //colocar nome da pasta em relação ao teste
// define variable
uint8_t sd_answer;

// Define socket que será usado
//////////////////////////////////////////////
uint8_t socket = SOCKET0;
//////////////////////////////////////////////


// Define parametros do Device e Back-End
////////////////////////////////////////////////////////////
char DEVICE_EUI[]  = "0004A30B00238BBC";
char DEVICE_ADDR[] = "26011511";
char NWK_SESSION_KEY[] = "C1BAF5D7377C40D8CAADAC5F882DE505";
char APP_SESSION_KEY[] = "825295CFC549C8FD299BFAE663F8C8F9";
//////////////////////////////////////////////////////////

// Define a porta usada no Back-End: de 1 até 223
uint8_t PORT = 35;

// variáveis
uint8_t error;
int Ctotal = 0;
int Cerro = 0;
int AckAntes = 0;
float Retransmissao = 0;

char valor[4];

void setup() 
{
  USB.ON();
  USB.println(F("LoRaWAN - Envio de pacote para a integracao Cayenne\n"));


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
    USB.println(F("3. Power level set OK"));     
  }
  else 
  {
    USB.print(F("3. Power level set error = ")); 
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 3. Configura o EUI do Device
  //////////////////////////////////////////////

  error = LoRaWAN.setDeviceEUI(DEVICE_EUI);

  // Verifica Status
  if( error == 0 ) 
  {
    USB.println(F("4. Device EUI set OK"));     
  }
  else 
  {
    USB.print(F("4. Device EUI set error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 4. Configura Endereço do Device
  //////////////////////////////////////////////

  error = LoRaWAN.setDeviceAddr(DEVICE_ADDR);

  // Verifica Status
  if( error == 0 ) 
  {
    USB.println(F("5. Device address set OK"));     
  }
  else 
  {
    USB.print(F("5. Device address set error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 5. Configura o Network Session
  //////////////////////////////////////////////

  error = LoRaWAN.setNwkSessionKey(NWK_SESSION_KEY);

  // Verifica Status
  if( error == 0 ) 
  {
    USB.println(F("6. Network Session Key set OK"));     
  }
  else 
  {
    USB.print(F("6. Network Session Key set error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 6. Configura o Application Key
  //////////////////////////////////////////////

  error = LoRaWAN.setAppSessionKey(APP_SESSION_KEY);

  // Verifica Status
  if( error == 0 ) 
  {
    USB.println(F("7. Application Session Key set OK"));     
  }
  else 
  {
    USB.print(F("7. Application Session Key set error = ")); 
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
      //USB.println(F("8. Channel status set OK")); 
    }
    else
    {
      USB.print(F("8. Channel status set error = ")); 
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
    USB.println(F("9. Save configuration OK"));     
  }
  else 
  {
    USB.print(F("9. Save configuration error = ")); 
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


  LoRaWAN.setUpCounter(0); //Zera contador de uplink
  LoRaWAN.setDownCounter(0); //Zera contador de downlink
  
/*
 * Desconmentar os delete e criar para criar a primeira vez que for começar o teste e depois deixa-los comentados para que
 * após o teste seja possivel visualizar no monitor serial
 */
 
  SD.ON();
  
      SD.del(arq); // Deleta arquivo **COMENTAR QUANDO FOR COMEÇAR O TESTE
      SD.rmdir(pasta); //Apaga diretório **COMENTAR QUANDO FOR COMEÇAR O TESTE
      sd_answer = SD.mkdir(pasta); //Cria o diretório **COMENTAR QUANDO FOR COMEÇAR O TESTE

       //Verifica se foi criado corretamente a pasta
      if( sd_answer == 1 )
      { 
        USB.println(F("path created"));
      }
      else
      {
        USB.println(F("mkdir failed"));
      }
  
    // Cria arquivo
    sd_answer = SD.create(arq); //**COMENTAR QUANDO FOR COMEÇAR O TESTE
    
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


uint8_t CayenneLPP::addContador(uint8_t channel, int Contador)//Função para criar payload para os dados de um Contador
{
  if ((cursor + LPP_CONTADOR_SIZE) > maxsize) {
        return 0;
  }
  buffer[cursor++] = channel; //Guarda o numero do canal destinado a GPS no payload
  buffer[cursor++] = LPP_CONTADOR; //Guarda o código do Contador (código definido pelo Cayenne para que o mesmo perceba que os dados seguintes se referem ao dado)
  //***OBS: Neste caso a função está usando o código do luximetro do cayenne pois é o que melhor representa o contador, visto que o Cayenne não possui código para contador 
  
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
  
      //////////////////////////////////////////////
      // Cria o Payload
      //////////////////////////////////////////////
      USB.println(F("Criando Payload"));
      int size = 0;
      Payload.reset(); //Reseta Payload
      USB.print(F("Porcentagem de bateria: "));
      USB.println(PWR.getBatteryLevel(),DEC); //Printa na tela o nivel de bateria do Device
      LoRaWAN.getRetries(); //Comando para atualizar o contador interno do device
       
      //////////////////////////////////////////////
      // Montando o Payload
      //////////////////////////////////////////////
      Ctotal++; //Contador de Pacotes Criados e que tentaram ser enviados
  
      size = Payload.addContador(0,LoRaWAN._downCounter); //Adiciona o contador de Ack ao payload 
      
      Payload.addContador(1,Retransmissao); //Adiciona o contador de retransmissões
      Payload.addContador(3,Ctotal); //Adiciona o contador de pacotes
      Payload.addContador(2,Cerro); //Adiciona o contador de erros

      AckAntes = LoRaWAN._downCounter; //Salva o numero de ACK recebidos antes da transmissão
      
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
      
      error = LoRaWAN.setDataRate(3); //Ajusta o Data Rate em todo ciclo de loop
      //LoRaWAN.setADR("off"); //Desativa o ajuste de Data Rate **O PROTOCOLO LoRaWAN RECOMENDA QUE O ADR FIQUE ATIVADO
      
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
      LoRaWAN.getRetries();

      char toWrite [200]; //Cria string para armazenar o Payload e joga-lo dentro do SD
      Utils.hex2str( Payload.getBuffer(), toWrite,Payload.getSize()); //Transforma o Paylod em str
      USB.println(toWrite); //Mostra o Payload no monitor serial

      //Caso a diferença entre o numero de ACK atual e o anterior (antes de ser enviado o pacote) seja maior que 1, significa que houve retransmissão, por isso atualiza o contador
      if((LoRaWAN._downCounter - AckAntes) > 1)
      {
        Retransmissao = Retransmissao + (LoRaWAN._downCounter - AckAntes-1);//(Dentro do parenteses esta o valor de retransmissões que ocorreram neste envio de pacote)  
      }
      
      char *nome; //Cria variavel para colocar nomeclaturas dentro do SD
      
      SD.appendln(arq, toWrite); //Armazena o valor do Payload dentro do SD

      SD.append(arq, "Contador de Ack: ");
      Utils.float2String(LoRaWAN._downCounter, valor,1);
      SD.appendln(arq,valor);
      
      SD.append(arq, "Contador de pacote perdido: ");
      Utils.float2String(Cerro, valor,1);
      SD.appendln(arq,valor);
      
      SD.append(arq, "Contador de pacote enviado: ");
      Utils.float2String(Ctotal, valor,1);
      sd_answer = SD.appendln(arq,valor);

      SD.append(arq, "Retransmissoes no TTN: ");
      Utils.float2String(Retransmissao, valor,1);
      sd_answer = SD.appendln(arq,valor);

      SD.append(arq,"\n" );
     
      SD.showFile(arq);
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

      delay(300);

}
