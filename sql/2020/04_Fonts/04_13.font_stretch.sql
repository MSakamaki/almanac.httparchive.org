#standardSQL
#font_stretch
CREATE TEMPORARY FUNCTION usesFontStretch(css STRING)
RETURNS ARRAY<STRING> LANGUAGE js AS '''
try {
    var reduceValues = (values, rule) => {
        if ('rules' in rule) {
            return rule.rules.reduce(reduceValues, values);
        }
        if (!('declarations' in rule)) {
            return values;
        }
        return values.concat(rule.declarations.filter(d => d.property.toLowerCase() == 'font-stretch').map(d => d.value));
    };
    var $ = JSON.parse(css);
    return $.stylesheet.rules.reduce(reduceValues, []);
} catch (e) {
    return [];
}
''';
SELECT
  client,
  font_stretch,
  COUNT(DISTINCT page) AS freq_stretch,
  total_page,
  COUNT(DISTINCT page)*100/total_page AS pct_strech
FROM
  `httparchive.almanac.parsed_css`,
  UNNEST(usesFontStretch(css)) AS font_stretch
JOIN (
  SELECT
    _TABLE_SUFFIX AS client,
    COUNT(0) AS total_page
  FROM
    `httparchive.summary_pages.2020_08_01_*`
  GROUP BY
    client)
USING
  (client)
WHERE
  ARRAY_LENGTH(usesFontStretch(css))>0 and date='2020-08-01'
GROUP BY
  client, 
  font_stretch,
  total_page
ORDER BY
  freq_stretch