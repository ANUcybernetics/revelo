extern crate petgraph;
extern crate rustler;
extern crate rustworkx_core;

use petgraph::graph::{DiGraph, NodeIndex};
use rustler::NifResult;
use rustworkx_core::connectivity::johnson_simple_cycles;
use std::collections::HashMap;

#[rustler::nif]
fn find_cycles(relationships: Vec<(String, String, String)>) -> NifResult<Vec<Vec<String>>> {
    // Create a directed graph from relationships
    let mut graph = DiGraph::<String, String>::new();
    let mut node_indices: HashMap<String, NodeIndex> = HashMap::new();
    let mut rel_map: HashMap<(String, String), String> = HashMap::new();

    // Add nodes
    for (rel_id, src_id, dst_id) in &relationships {
        if !node_indices.contains_key(src_id) {
            let idx = graph.add_node(src_id.clone());
            node_indices.insert(src_id.clone(), idx);
        }
        if !node_indices.contains_key(dst_id) {
            let idx = graph.add_node(dst_id.clone());
            node_indices.insert(dst_id.clone(), idx);
        }
        rel_map.insert((src_id.clone(), dst_id.clone()), rel_id.clone());
    }

    // Add edges
    for (rel_id, src_id, dst_id) in &relationships {
        let src_idx = node_indices[src_id];
        let dst_idx = node_indices[dst_id];
        graph.add_edge(src_idx, dst_idx, rel_id.clone());
    }

    // Handle self-cycles separately as the algorithm may not detect them reliably
    let self_cycles_vec: Vec<NodeIndex> = graph
        .node_indices()
        .filter(|n| graph.neighbors(*n).any(|x| x == *n))
        .collect();

    // Remove self-cycle edges temporarily
    let mut removed_self_edges = Vec::new();
    for node in &self_cycles_vec {
        let node_uuid = graph[*node].clone();
        while let Some(edge_index) = graph.find_edge(*node, *node) {
            let edge_data = graph.remove_edge(edge_index).unwrap();
            removed_self_edges.push((node_uuid.clone(), edge_data));
        }
    }

    let self_cycles = if self_cycles_vec.is_empty() {
        None
    } else {
        Some(self_cycles_vec)
    };

    // Find all simple cycles
    let mut cycles_iter = johnson_simple_cycles(&graph, self_cycles);
    let mut all_cycles = Vec::new();

    // Create a mapping from NodeIndex to UUID
    let mut index_to_uuid: HashMap<NodeIndex, String> = HashMap::new();
    for (uuid, idx) in &node_indices {
        index_to_uuid.insert(*idx, uuid.clone());
    }

    // Collect cycles and convert to relationship IDs
    while let Some(cycle) = cycles_iter.next(&graph) {
        let mut cycle_rel_ids = Vec::new();

        // Convert indices to UUIDs and then find the relationship IDs
        for i in 0..cycle.len() {
            let src_idx = cycle[i];
            let dst_idx = cycle[(i + 1) % cycle.len()];

            let src_uuid = &index_to_uuid[&src_idx];
            let dst_uuid = &index_to_uuid[&dst_idx];

            if let Some(rel_id) = rel_map.get(&(src_uuid.clone(), dst_uuid.clone())) {
                cycle_rel_ids.push(rel_id.clone());
            } else {
                // This shouldn't happen if the graph was built correctly
                return Err(rustler::Error::Term(Box::new(
                    "Edge not found in relationship map",
                )));
            }
        }

        // Sort each cycle so that the smallest UUID comes first
        if !cycle_rel_ids.is_empty() {
            let min_idx = cycle_rel_ids
                .iter()
                .enumerate()
                .min_by(|(_, a), (_, b)| a.cmp(b))
                .map(|(idx, _)| idx)
                .unwrap_or(0);

            // Rotate the cycle to start with the smallest UUID
            let rotated_cycle: Vec<String> = cycle_rel_ids
                .iter()
                .cycle()
                .skip(min_idx)
                .take(cycle_rel_ids.len())
                .cloned()
                .collect();

            all_cycles.push(rotated_cycle);
        }
    }

    // Add self-cycles back as separate cycles
    for (_node_uuid, rel_id) in removed_self_edges {
        all_cycles.push(vec![rel_id]);
    }

    Ok(all_cycles)
}

rustler::init!("Elixir.Revelo.Diagrams.GraphAnalyser");
