/* Formatted on 2018. 06. 13. 13:27:24 (QP5 v5.115.810.9015) */
DROP TABLE t_prop_pace;
COMMIT;

CREATE TABLE t_prop_pace
AS
   SELECT   a.f_ivk,
            x.f_lean_tip,
            CASE
               WHEN b.f_termcsop = 'TLP' THEN 'LAK'
               WHEN b.f_termcsop IN ('GÉPK', 'GÉP') THEN 'GFB'
               ELSE b.f_termcsop
            END
               AS f_termcsop,
            a.f_int_begin,
            a.f_int_end,
            TRUNC (f_int_end, 'hh') + 1 / 1440 * 60 AS zart_ora,
            CASE
               WHEN f_int_end >= TRUNC (SYSDATE, 'ddd') THEN 'curr'
               ELSE 'hist'
            END
               AS pool,
            kontakt.basic.get_userid_kiscsoport (a.f_userid) AS csoport,
            UPPER (kontakt.basic.get_userid_login (a.f_userid)) AS login,
            TO_NUMBER (kontakt.basic.get_userid_torzsszam (a.f_userid))
               AS torzsszam,
            kontakt.basic.get_userid_nev (a.f_userid) AS nev,
            CASE
               WHEN (   a.f_alirattipusid BETWEEN 1896 AND 1930
                     OR a.f_alirattipusid BETWEEN 1944 AND 1947
                     OR a.f_alirattipusid IN ('1952', '2027', '2028', '2021'))
               THEN
                  kontakt.basic.get_alirattipusid_alirattipus (
                     a.f_alirattipusid
                  )
               ELSE
                  'Egyéb iraton'
            END
               AS tevekenyseg,
            f_oka,
            (a.f_int_end - a.f_int_begin) * 1440 AS cklido,
            CASE
               WHEN afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) =
                       'KÜT ügyfélkezelés indítása, általános, KÜT'
               THEN
                  'KUT'
               WHEN afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) LIKE
                       '%További ajánlati tevékenység szükséges tovább%'
                    OR afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) LIKE
                         '%Senior validálásra%'
               THEN
                  'Tovabbad'
               WHEN afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) LIKE
                       '%Szakmai segítséget kérek%'
               THEN
                  'Segitsegker'
               WHEN afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) LIKE
                       '%Várakoztatás szükséges%'
                    OR afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) LIKE
                         '%Nem zárható le/Reponálás funkció/Reponálás%'
               THEN
                  'Varakoztat'
               WHEN afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) LIKE
                       '%ötvényesítve%'
                    OR afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) LIKE
                         '%lutasítva%'
               THEN
                  'Lezar'
               WHEN afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) LIKE
                       '%átadás csoportvezetõnek%'
               THEN
                  'Csopveznek'
               WHEN afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) LIKE
                       '%csoportvezetõi döntés%'
               THEN
                  'Csopvez_dont'
               WHEN afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) LIKE
                       '%Nem indítható rögzítés%'
               THEN
                  'Rendszerhiba'
               ELSE
                  'Egyeb'
            END
               AS kimenet
     FROM   afc.t_afc_wflog_lin2 a,
            kontakt.t_lean_alirattipus x,
            kontakt.t_ajanlat_attrib b
    WHERE   a.f_int_end BETWEEN TRUNC (SYSDATE - 180, 'ddd')
                              AND  TRUNC (SYSDATE, 'hh') - 1/1440 -- till hh:59 of last closed hour
            AND (a.f_int_end - a.f_int_begin) * 1440 < 45
            AND (a.f_int_end - a.f_int_begin) * 86400 > 1
            AND afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) IS NOT NULL
            AND a.f_ivk = b.f_ivk(+)
            AND a.f_alirattipusid = x.f_alirattipusid
            AND UPPER (kontakt.basic.get_userid_login (a.f_userid)) NOT IN
                     ('MARKIB', 'SZERENCSEK')
            AND x.f_lean_tip = 'AL'
            AND b.f_termcsop IS NOT NULL;

COMMIT;