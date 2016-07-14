--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: umsaetze; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE umsaetze (
    id integer NOT NULL,
    "Waehrung" text,
    "VWZ1" text,
    "VWZ2" text,
    "VWZ3" text,
    "VWZ4" text,
    "VWZ5" text,
    "VWZ6" text,
    "VWZ7" text,
    "VWZ8" text,
    "VWZ9" text,
    "VWZ10" text,
    "VWZ11" text,
    "VWZ12" text,
    "VWZ13" text,
    "VWZ14" text,
    "Kontonummer" integer,
    "Textschluessel" integer,
    "Buchungstag" date,
    "Wertstellung" date,
    "Name" text,
    "Betrag" numeric,
    "Buchungstext" text,
    "Kontostand" numeric
);


ALTER TABLE public.umsaetze OWNER TO postgres;

--
-- Name: kontostand; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW kontostand AS
 SELECT a.kontonummer,
    umsaetze."Kontostand" AS kontostand
   FROM (umsaetze
     JOIN ( SELECT max(umsaetze_1.id) AS maxid,
            umsaetze_1."Kontonummer" AS kontonummer
           FROM umsaetze umsaetze_1
          GROUP BY umsaetze_1."Kontonummer") a ON (((a.kontonummer = umsaetze."Kontonummer") AND (umsaetze.id = a.maxid))));


ALTER TABLE public.kontostand OWNER TO postgres;

--
-- Name: accounts_catalogue; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW accounts_catalogue AS
 SELECT DISTINCT umsaetze."Kontonummer" AS id,
    kontostand.kontostand
   FROM (umsaetze
     JOIN kontostand ON ((umsaetze."Kontonummer" = kontostand.kontonummer)));


ALTER TABLE public.accounts_catalogue OWNER TO postgres;

--
-- Name: transaktionen; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW transaktionen AS
 SELECT a.id,
    a.kontonummer,
    a.kategorie,
    a.belegtext,
    a.buchungstag,
    a.wertstellungstag,
    a.empfaenger,
    a.betrag,
    ((((a.kategorie || ' '::text) || a.belegtext) || ' '::text) || a.empfaenger) AS description
   FROM ( SELECT umsaetze.id,
            umsaetze."Kontonummer" AS kontonummer,
            umsaetze."Buchungstext" AS kategorie,
            (((((((((((((umsaetze."VWZ1" || umsaetze."VWZ2") || umsaetze."VWZ3") || umsaetze."VWZ4") || umsaetze."VWZ5") || umsaetze."VWZ6") || umsaetze."VWZ7") || umsaetze."VWZ8") || umsaetze."VWZ9") || umsaetze."VWZ10") || umsaetze."VWZ11") || umsaetze."VWZ12") || umsaetze."VWZ13") || umsaetze."VWZ14") AS belegtext,
            umsaetze."Buchungstag" AS buchungstag,
            umsaetze."Wertstellung" AS wertstellungstag,
            umsaetze."Name" AS empfaenger,
            umsaetze."Betrag" AS betrag
           FROM umsaetze) a;


ALTER TABLE public.transaktionen OWNER TO postgres;

--
-- Name: umsaetze_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE umsaetze_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.umsaetze_id_seq OWNER TO postgres;

--
-- Name: umsaetze_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE umsaetze_id_seq OWNED BY umsaetze.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY umsaetze ALTER COLUMN id SET DEFAULT nextval('umsaetze_id_seq'::regclass);


--
-- Name: umsaetze_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY umsaetze
    ADD CONSTRAINT umsaetze_pkey PRIMARY KEY (id);


--
-- Name: public; Type: ACL; Schema: -; Owner: daboe01
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM daboe01;
GRANT ALL ON SCHEMA public TO daboe01;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

