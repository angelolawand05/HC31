# HC31 manuscript figure / result → retained script map

| Manuscript item | Retained code | Status |
|---|---|---|
| Figure 1 | None — reproduced source-study apparatus image | Not HC31-generated |
| Figure 2 | `01_primary_beta/plotburstlocs.m` | Direct |
| Figure 3A | `01_primary_beta/hc31_batch11A_event_trace_QC_PLAIN_SCRIPT.m` | Direct |
| Figure 3B / detector counts | `01_primary_beta/hc31_extract_beta_bursts_over_time_FUNC.m` | Direct |
| Figure 4 | `02_final_temporal_spatial_stats/run_b4_updated_stats.m` + helpers | Direct final figure runner |
| Figure 5 | `02_final_temporal_spatial_stats/run_b4_updated_stats.m` + helpers | Direct final figure runner |
| Figure 6 | `01_primary_beta/speedcorr.m` | Direct |
| Figure 7 | `01_primary_beta/hc31_extract_beta_bursts_over_time_FUNC.m`; `hc31_run1_beta_timecourse_plots_PLAIN_SCRIPT.m` | Direct |
| Figure 8 | `01_primary_beta/nfbeta.m`; `02_final_temporal_spatial_stats/run_b4_updated_stats.m` | Direct for displayed summaries; final circular-shift code gap noted in README |
| Figure 9A | `01_primary_beta/speedcorr.m`; Batch 4 updated-statistics runner | Direct |
| Figure 9B | `01_primary_beta/hc31_batch2_burst_frequency_heatmaps.m` | Direct |
| Figures 10–11 | `03_spectral/psdspec_fixed_groupmean.m`; `03_spectral/batch5_force/run_b5_force.m` + helpers | Direct retained implementation |
| Figure 12 | `03_spectral/batch6_force/run_b6_force.m` + helpers | Direct |
| Figure 13 | `04_neuronal_beta/batch8_force/run_b8_force.m` + helpers | Closest archived source; exact final event-control implementation gap noted |
| Figure 14 | `04_neuronal_beta/hc31_batch11C_PETH_phase_locking_PLAIN_SCRIPT.m` | Direct |
| Figure 15 | `05_high_frequency_candidates/hc31_batch11K_candidate_ripple_manual_QC_PLAIN_SCRIPT_FIXED.m` plus downstream screening/tiering scripts | Direct waveform QC; ridge model gap noted |
| Figure 16 | Candidate master/tiering and `06_candidate_firing_amplitude/batch11O/` scripts | Related/upstream; exact final 50-seed matched-control script not located |
| Figure 17 | Batch 11O Stage B + corrected QC + `batch11P_synthesis` | Direct current plot lineage |
| Figure 18 | Batch 11O Stage B + corrected QC | Direct corrected statistics lineage |
| Figure 19 | `07_spike_order/hc31_batch11F_replay_sorted_rasters_PLAIN_SCRIPT.m` → `hc31_batch11I_shuffle_controlled_replay_sequences_PLAIN_SCRIPT.m` | Direct |
| Figure 20 | Batch 11I for original ordering; later alternative-ordering standalone scripts not found in B1–B4 | Partial — gap noted |

## Analysis-only results without a unique figure

- Entry novelty windows: `01_primary_beta/hc31_entry_novelty_sensitivity_PLAIN_SCRIPT.m`
- Spatial novelty statistics / model-ready outputs: `01_primary_beta/hc31_batch4_novelty_statistics.m` plus final Batch 4 updated-statistics runner; final 2M circular-shift and hypergeometric held-out implementations are not retained as standalone B1–B4 scripts.
- Candidate state classification: `05_high_frequency_candidates/hc31_batch11M3_corrected_pre_rest_post_state_classification_PLAIN_SCRIPT.m`
- Final candidate master/tiering: `05_high_frequency_candidates/batch11Nplus/`
- Candidate population recruitment / state-rate analyses: `06_candidate_firing_amplitude/batch11O/hc31_batch11O_population_recruitment_and_state_rates_PLAIN_SCRIPT.m`
- Candidate beta2 movement-matched amplitude analysis: `06_candidate_firing_amplitude/batch11O/hc31_batch11O_awake_beta2_speed_matched_PLAIN_SCRIPT.m` + final correction script.
