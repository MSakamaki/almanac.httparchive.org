#standardSQL
# Distribution of response body size by redirected third parties
# HTTP status codes documentation: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status

WITH requests AS (
  SELECT
    'desktop' AS client,
    req_host AS host,
    status,
    respBodySize AS body_size
  FROM
    `httparchive.summary_requests.2020_08_01_desktop`
  UNION ALL (
    SELECT
      'mobile' AS client,
      req_host AS host,
      status,
      respBodySize AS body_size,
    FROM
      `httparchive.summary_requests.2020_08_01_mobile`
  )
),
third_party AS (
  SELECT
    domain
  FROM
    `httparchive.almanac.third_parties`
  WHERE
    date = '2020-08-01'
),
base AS (
  SELECT
    client,
    domain,
    IF(status BETWEEN 300 AND 399, 1, 0) AS redirected,
    body_size
  FROM
    requests
  LEFT JOIN
    third_party
  ON
    NET.HOST(requests.host) = NET.HOST(third_party.domain)
)

SELECT
  client,
  percentile,
  APPROX_QUANTILES(body_size, 1000)[OFFSET(percentile)] AS approx_redirect_body_size
FROM
  base,
UNNEST(GENERATE_ARRAY(0, 1000, 1)) AS percentile
WHERE
  redirected = 1
GROUP BY
  client,
  percentile
ORDER BY
  client,
  percentile
