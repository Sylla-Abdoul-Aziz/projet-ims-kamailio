#!/bin/bash
# Création des APN et des abonnés Alice et Bob dans PyHSS (API REST, port 8080)
A=http://192.168.1.121:8080
j() { curl -s -X PUT "$A/$1" -H 'Content-Type: application/json' -d "$2"; echo; }
j apn/ '{"apn":"internet","apn_ambr_dl":0,"apn_ambr_ul":0}'
j apn/ '{"apn":"ims","apn_ambr_dl":0,"apn_ambr_ul":0}'
for n in 1 2; do
  IMSI=00101000001000$n; MSISDN=1000$n
  j auc/ '{"imsi":"'$IMSI'","ki":"5BAD8598D1F631E3ED76F9333B8AA26F","opc":"BA5205DDC6FCA1DF6B83A1CC69859514","amf":"8000","sqn":1}'
  j subscriber/ '{"imsi":"'$IMSI'","enabled":true,"auc_id":'$n',"default_apn":1,"apn_list":"1,2","msisdn":"'$MSISDN'","ue_ambr_dl":0,"ue_ambr_ul":0}'
  j ims_subscriber/ '{"imsi":"'$IMSI'","msisdn":"'$MSISDN'","msisdn_list":"['$MSISDN']","ifc_path":"default_ifc.xml","scscf":"sip:scscf.ims.mnc001.mcc001.3gppnetwork.org:6060","scscf_realm":"ims.mnc001.mcc001.3gppnetwork.org","scscf_peer":"scscf.ims.mnc001.mcc001.3gppnetwork.org"}'
done
