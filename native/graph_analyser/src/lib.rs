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

    // Add nodes and edges in a single pass
    for (rel_id, src_id, dst_id) in &relationships {
        // We can optimize this since we know src_id != dst_id (no self-loops)
        let src_idx = *node_indices
            .entry(src_id.clone())
            .or_insert_with(|| graph.add_node(src_id.clone()));

        let dst_idx = *node_indices
            .entry(dst_id.clone())
            .or_insert_with(|| graph.add_node(dst_id.clone()));

        graph.add_edge(src_idx, dst_idx, rel_id.clone());
        rel_map.insert((src_id.clone(), dst_id.clone()), rel_id.clone());
    }

    // Since we have no self-loops, we can directly call johnson_simple_cycles
    let mut cycles_iter = johnson_simple_cycles(&graph, None);
    let mut all_cycles = Vec::new();

    // Create a mapping from NodeIndex to UUID (more efficient approach)
    let index_to_uuid: HashMap<NodeIndex, &String> = node_indices
        .iter()
        .map(|(uuid, &idx)| (idx, uuid))
        .collect();

    // Collect cycles and convert to relationship IDs
    while let Some(cycle) = cycles_iter.next(&graph) {
        if cycle.is_empty() {
            continue;
        }

        let mut cycle_rel_ids = Vec::with_capacity(cycle.len());

        // Convert indices to UUIDs and then find the relationship IDs
        for i in 0..cycle.len() {
            let src_idx = cycle[i];
            let dst_idx = cycle[(i + 1) % cycle.len()];

            let src_uuid = index_to_uuid[&src_idx];
            let dst_uuid = index_to_uuid[&dst_idx];

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
            // Find the index of the minimum element more efficiently
            let min_idx = cycle_rel_ids
                .iter()
                .enumerate()
                .min_by_key(|(_, id)| *id)
                .map(|(idx, _)| idx)
                .unwrap_or(0);

            // Rotate the cycle to start with the smallest UUID
            // Create a new vector without using cycle() iterator for better performance
            let mut rotated_cycle = Vec::with_capacity(cycle_rel_ids.len());
            rotated_cycle.extend_from_slice(&cycle_rel_ids[min_idx..]);
            rotated_cycle.extend_from_slice(&cycle_rel_ids[0..min_idx]);

            all_cycles.push(rotated_cycle);
        }
    }

    Ok(all_cycles)
}

rustler::init!("Elixir.Revelo.Diagrams.GraphAnalyser");
