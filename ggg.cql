TASK 0 -
Part 1

MATCH (z1:zone)-[rel :CONNECTS]->(z2:zone) WHERE z1.id=z2.id RETURN count(rel)

Part 2

MATCH (z:zone)
WHERE (SIZE([(z)-[:CONNECTS]->(x:zone)|x]) = 1 AND EXISTS((z)-[:CONNECTS]->(z))) OR (NOT (z)-[:CONNECTS]->(:zone))
RETURN z

TASK 1-

//graph projection

CALL gds.graph.create(
    '220509387-louvain',
    'zone',
    {
        CONNECTS: {
            orientation: 'UNDIRECTED'
        }
    },
    {
        relationshipProperties: 'trips'
    }
)

// running on stats mode
CALL gds.louvain.stats('220509387-louvain', {relationshipWeightProperty: 'trips'})
YIELD communityCount

// running on stream

CALL gds.louvain.stream('220509387-louvain', {relationshipWeightProperty: 'trips'})
YIELD nodeId, communityId
RETURN gds.util.asNode(nodeId).id AS zone, communityId as community
ORDER BY community ASC      //ordering by community ascending


TASK 2-
//projecting graph
CALL gds.graph.create(
  '220509387-pagerank',
  'zone',
  'CONNECTS',
  {
    relationshipProperties: 'trips'
  }
)

//running stats mode

CALL gds.pageRank.stats('220509387-pagerank', {
  dampingFactor: 0.75,
  relationshipWeightProperty: 'trips'
})
YIELD centralityDistribution
RETURN centralityDistribution.max AS max, centralityDistribution.min AS min

// running streams mode

CALL gds.pageRank.stream('220509387-pagerank', {
  dampingFactor: 0.75,
  relationshipWeightProperty: 'trips'
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).id AS zone_id, score as centrality_score
ORDER BY zone_id ASC


TASK 3-

// Finding top 3 highest centrality zones per each community:
// including Manhattan

MATCH (z:zone)
WITH z
ORDER BY z.centrality DESC
WITH z.community as community, COLLECT(z.id)[..3] as top_three
UNWIND top_three AS zone_id
RETURN zone_id, community as community_id

// without Manhattan
MATCH (z:zone)-[:IN]->(b:borough)
WHERE b.name <> "Manhattan"
WITH z
ORDER BY z.centrality DESC
WITH z.community as community, COLLECT(z.id)[..3] as top_three
UNWIND top_three as zone_id
RETURN zone_id, community as community_id

