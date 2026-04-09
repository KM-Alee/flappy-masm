; game.inc - Shared data and procedure declarations for all modules
;
; Every .asm file includes this to access shared game state and call
; procedures defined in other modules.

option casemap:none

ifdef TARGET_WINDOWS
include include/windows.inc
else
; Pull in platform constants (STDIN_FD, TCGETS, signal numbers, etc.)
; and libc function declarations (write, read, poll, ioctl, etc.)
include include/linux.inc
endif

; ---------------------------------------------------------------------------
; Shared data (defined in main.asm, referenced everywhere)
; ---------------------------------------------------------------------------

; ANSI escape sequences
externdef init_sequence:byte
externdef restore_sequence:byte
externdef reset_style_sequence:byte
externdef home_sequence:byte
externdef fg_prefix:byte
externdef bg_prefix:byte
externdef color_suffix:byte

; String literals
externdef tty_error_message:byte
externdef highscore_path:byte
externdef debug_env_name:byte
externdef swoosh_sound_command:byte
externdef point_sound_command:byte
externdef hit_sound_command:byte
externdef die_sound_command:byte
externdef title_line_1:byte
externdef title_line_2:byte
externdef title_line_3:byte
externdef title_line_4:byte
externdef pause_line:byte
externdef game_over_line:byte
externdef restart_line:byte
externdef score_label_s:byte
externdef best_label_s:byte
externdef warning_line_1:byte
externdef warning_line_2:byte
externdef debug_prefix_1:byte
externdef debug_prefix_2:byte
externdef debug_prefix_3:byte
externdef debug_prefix_4:byte

; Color palette

; OS / terminal buffers
externdef saved_termios:byte
externdef raw_termios:byte
externdef winsize_buffer:byte
externdef pollfd_buffer:byte
externdef clock_buffer:byte
externdef sleep_buffer:byte
externdef input_buffer:byte
externdef console_info_buffer:byte

; Scratch buffers for number formatting
externdef number_reverse:byte
externdef number_buffer:byte
externdef debug_buffer:byte

; Rendering buffers
externdef cell_buffer:byte
externdef out_buffer:byte

; Scalar game state
externdef terminal_active:dword
externdef debug_enabled:dword
externdef small_terminal:dword
externdef exit_requested:dword
externdef resize_requested:dword
externdef game_state:dword
externdef term_cols:dword
externdef term_rows:dword
externdef bird_y:dword
externdef bird_velocity:dword
externdef score_value:dword
externdef best_score:dword
externdef frame_counter:dword
externdef pipe_gap_height:dword
externdef pipe_spacing:dword
externdef bird_column:dword
externdef ground_top_row:dword

; Pipe arrays
externdef pipes_x:dword
externdef pipes_gap_y:dword
externdef pipes_scored:dword

; 64-bit state
externdef rng_state:qword
externdef last_frame_ns:qword
externdef accumulator_ns:qword
externdef qpc_frequency:qword

; ---------------------------------------------------------------------------
; Procedures exported by each module
; ---------------------------------------------------------------------------

; terminal.asm
externdef SetupTerminal:proc
externdef RestoreTerminal:proc
externdef InstallProcessHooks:proc
externdef UpdateTerminalGeometry:proc

; input.asm
externdef PollInput:proc
externdef HandleFlapKey:proc
externdef HandlePauseKey:proc
externdef HandleRestartKey:proc

; gameplay.asm
externdef RecomputeLayout:proc

; physics.asm
externdef UpdateGame:proc
externdef ResetRun:proc
externdef StartRun:proc

; render.asm
externdef RenderFrame:proc

; util.asm
externdef DetectDebugMode:proc
externdef SeedRng:proc
externdef ClockNowNs:proc
externdef SleepUntilNextTick:proc
externdef LoadBestScore:proc
externdef SaveBestScore:proc
externdef PlaySwooshSound:proc
externdef PlayPointSound:proc
externdef PlayHitSound:proc
externdef PlayDieSound:proc
externdef WriteString:proc
externdef AppendString:proc
externdef AppendUnsignedToStream:proc
externdef StringLength:proc
externdef UIntToString:proc
externdef CopyString:proc
