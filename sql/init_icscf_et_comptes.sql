-- Déclaration du S-CSCF auprès de l'I-CSCF
USE icscf;
INSERT INTO nds_trusted_domains VALUES (1, 'ims.mnc001.mcc001.3gppnetwork.org');
INSERT INTO s_cscf VALUES (1, 'S-CSCF du TP', 'sip:scscf.ims.mnc001.mcc001.3gppnetwork.org:6060');
INSERT INTO s_cscf_capabilities VALUES (1, 1, 0), (2, 1, 1);
-- Comptes d'accès des trois CSCF
CREATE USER 'pcscf'@'localhost' IDENTIFIED BY 'heslo';
CREATE USER 'pcscf'@'127.0.0.1' IDENTIFIED BY 'heslo';
CREATE USER 'scscf'@'localhost' IDENTIFIED BY 'heslo';
CREATE USER 'scscf'@'127.0.0.1' IDENTIFIED BY 'heslo';
CREATE USER 'icscf'@'localhost' IDENTIFIED BY 'heslo';
GRANT DELETE, INSERT, SELECT, UPDATE ON pcscf.* TO 'pcscf'@'localhost', 'pcscf'@'127.0.0.1';
GRANT DELETE, INSERT, SELECT, UPDATE ON scscf.* TO 'scscf'@'localhost', 'scscf'@'127.0.0.1';
GRANT DELETE, INSERT, SELECT, UPDATE ON icscf.* TO 'icscf'@'localhost';
FLUSH PRIVILEGES;
