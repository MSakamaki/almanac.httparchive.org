#standardSQL
#variable_font_with_fcp
CREATE TEMP FUNCTION getName(font_details STRING) RETURNS STRING LANGUAGE js AS '''
try {
  const metadata = RegExp('(not to be used for anything other than web font use!|web use only|web_use_only|:|;|^google$|copyright|©|(c)|rights reserved|published by|generated by|property of|trademark|version|v\\d+|release|untitled|^bold$|^light$|^semibold$|^defaults$|^normal$|^regular$|^[a-f0-9]+$|Vernon Adams|Jan Kovarik|Jan Kovarik|Mark Simonson|Paul D. Hunt|Kai Bernau|Kris Sowersby|Joshua Darden|Jos Buivenga|Yugo Kajiwara|Moslem Ebrahimi|Hadrien Boyer|Russell Benson|Ryan Martinson|Joen Asmussen|Olivier Gourvat|Hannes von Doehren|René Bieder|House Industries|GoDaddy|TypeSquare|Dalton Maag Ltd|_null_name_substitute_|^font$|Moveable Type)', 'i')
  return Object.values(JSON.parse(font_details).names).find(name => {
    name = name.trim();
    return name.length > 2 &&
      !metadata.test(name) &&
      isNaN(Number(name));
  });
} catch (e) {
  return null;
}
''';
SELECT
  client,
  name,
  COUNT(DISTINCT page) AS freq_vf,
  total_page,
  COUNT(DISTINCT page) / total_page AS pct_vf,
  COUNT(DISTINCT IF(fast_fcp >= 0.75, page, NULL)) / COUNT(DISTINCT page) AS pct_good_fcp_vf,
  COUNT(DISTINCT IF(NOT(slow_fcp >= 0.25) AND NOT(fast_fcp >= 0.75), page, null))  / COUNT(DISTINCT page) AS pct_ni_fcp_vf,
  COUNT(DISTINCT IF(slow_fcp >= 0.25, page, null)) / COUNT(DISTINCT page) AS pct_poor_fcp_vf,
FROM (
  SELECT
    client,
    page,
    getName(JSON_EXTRACT(payload, '$._font_details')) AS name
  FROM
    `httparchive.almanac.requests`
  WHERE
    date = '2020-09-01' AND
    type = 'font' AND
    REGEXP_CONTAINS(JSON_EXTRACT(payload, '$._font_details.table_sizes'), '(?i)gvar'))
JOIN (
  SELECT
    _TABLE_SUFFIX AS client,
    COUNT(0) AS total_page
  FROM
    `httparchive.summary_pages.2020_09_01_*`
  GROUP BY
    _TABLE_SUFFIX) 
USING
  (client)
JOIN (
  SELECT DISTINCT
    CONCAT(origin, '/') AS page,
    IF(device = 'desktop', 'desktop', 'mobile') AS client,
    fast_fcp,
    slow_fcp,
  FROM
    `chrome-ux-report.materialized.device_summary`
  WHERE
    date = '2020-08-01')
USING
  (client, page)
WHERE
  name IS NOT NULL
GROUP BY
  client,
  name,
  total_page
HAVING
  freq_vf > 100
Order BY
  freq_vf DESC