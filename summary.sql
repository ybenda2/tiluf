SELECT
  c.number,
  c.full_name,
  c.comment,
  TO_CHAR(
    MAX(cs.updated_at) FILTER (WHERE cs.station = 4 AND cs.checked = TRUE) -
    MIN(cs.updated_at) FILTER (WHERE cs.station = 1 AND cs.checked = TRUE),
    'HH24:MI:SS'
  ) AS total_time
FROM cadets c
JOIN checkpoint_status cs ON cs.cadet_id = c.id
GROUP BY c.id, c.number, c.full_name
HAVING
  MAX(cs.updated_at) FILTER (WHERE cs.station = 4 AND cs.checked = TRUE) IS NOT NULL AND
  MIN(cs.updated_at) FILTER (WHERE cs.station = 1 AND cs.checked = TRUE) IS NOT NULL
ORDER BY c.number;