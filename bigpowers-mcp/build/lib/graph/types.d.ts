export interface GraphEntity {
    type: "entity";
    name: string;
    entityType: string;
    observations: string[];
}
export interface GraphRelation {
    type: "relation";
    from: string;
    to: string;
    relationType: string;
}
export type GraphLine = GraphEntity | GraphRelation;
export interface SkillGraph {
    entities: Map<string, GraphEntity>;
    relations: GraphRelation[];
}
export interface DependencyReport {
    skill: string;
    depends_on: string[];
    depended_by: string[];
    handoff_chain: string[];
    conventions: string[];
}
