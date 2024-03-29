const { Neo4jGraphQL } = require("@neo4j/graphql");
const { ApolloServer , gql} = require("apollo-server")
const neo4j = require("neo4j-driver")

const typeDefs = gql`
    type Movie {
        title: String
        actors: [Actor!]! @relationship(type: "ACTED_IN", direction: IN)
    }

    type Actor {
        name: String
        movies: [Movie!]! @relationship(type: "ACTED_IN", direction: OUT)
    }
`;


const driver = neo4j.driver(
    process.env.NEO4J_URI,
    neo4j.auth.basic("neo4j",process.env.NEO4J_PASSWD)
);

const neoSchema = new Neo4jGraphQL({typeDefs,driver});

neoSchema.getSchema().then((schema) => {
    const server = new ApolloServer({
        schema,
    });
  
    server.listen().then(({ url }) => {
        console.log(`🚀 Server ready at ${url}`);
    });
  })
  