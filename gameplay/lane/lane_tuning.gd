class_name LaneTuning
extends Resource
## Small data asset for rapid one-lane prototype iteration.

@export_range(1.0, 120.0, 0.1) var wave_interval: float = 20.0
@export_range(0.0, 30.0, 0.1) var first_wave_delay: float = 2.0
@export_range(0.0, 5.0, 0.05) var minion_spacing: float = 0.5
@export_range(0.0, 100.0, 0.5) var xp_radius: float = 10.0
