; NAME:      plot_FFT
;
; PURPOSE:   IDL procedure to read in a field surface data from a .txt file
;            generated by dumping ASCII data from the XOOPIC gui.
;
; CATEGORY:
;
; CALLING SEQUENCE:
;   plot_efield, f_name, x_name, y_name, z_name, ScaleFlag, ScaleInput
;
; INPUTS:
;   f_name:    string to specify base name of data file
;   x_name:    string to specify horizontal axis (must be "x" or "z")
;   y_name:    string to specify vertical   axis (must be "y" or "r")
;   z_name:    string to specify field component 
;              (must be "x", "y", "z", "r", or "phi")
;  ScaleFlag:  a flag to specify the scaling for length, i.e. of q:
;                  0 -> no scaling
;                  1 -> length scale = c/omega_0 (the laser frequency)
;                  2 -> length scale = 1/Kp (the plasma wave vector)
;  ScaleInput; irrelevant for ScaleFlag = 0, 
;                  omega_0 for ScaleFlag = 1,
;                  plasma density in [1/cm^3] for ScaleFlag = 2  
;
; OPTIONAL INPUTS:     None.
;
; KEYWORD PARAMETERS:  None.
;
; OUTPUTS:             None.
;
; OPTIONAL OUTPUTS:    None.
;
; COMMON BLOCKS:       None.
;
; SIDE EFFECTS:        None.
;
; RESTRICTIONS: 
;
;    The XOOPIC .txt files generally have some lines of text.  You
;      need to delete any such text lines, leaving only the data.
;
;    The argument base_name is a string that specifies the input
;      data file (base_name.txt) and is also used to name output files.
;
;    This procedure is specifically for use with the Ex data, but it
;      could be easily modified for any other type of surface data:
;      a) Rename the _file and _label variables appropriately.
;      b) Look for the "convert" comment below and change the scaling
;         of the data to something appropriate for the desired units.
;
; PROCEDURE:
;
; EXAMPLE:
;   plot_efield, "ey_fft_file", "x", "y", "y", 1, 1.77e14
;
; MODIFICATION HISTORY:
;   Nov  7, 2000:  original code (DLB)
;   May  1, 2001:  some generalization (DAD)
;   May 10, 2001:  renamed, with many changes (DLB)
;
;   Version: $Id: plot_FFT.pro 1779 2001-11-02 23:37:30Z bruhwile $
;
;   Copyright (c) 2000-2001 by Tech-X Corporation.  All rights reserved.


pro plot_FFT, base_name, x1Label, x2Label, EcomponentLabel, ScaleFlag, ScaleInput

; *****************************************************************
; Set flag for log plots
; *****************************************************************

; If log_plot_flag is nonzero, then this procedure will take the
; logarithm of the z-data

log_plot_flag = 0


; *****************************************************************
; Names for files and labels
; *****************************************************************

; Specify the text, restore and postscript file names
text_file    = base_name + '.txt'
restore_file = base_name + '.dat'

if (log_plot_flag eq 0) then begin
  ps_ccon_file = base_name + '_colorcon_lin.ps'
  ps_cont_file = base_name + '_contour_lin.ps'
  ps_surf_file = base_name + '_surface_lin.ps'
  ps_line_file = base_name + '_lineout_lin.ps'
  ps_tier_file = base_name + '_tiered_lin.ps'
endif else begin
  ps_ccon_file = base_name + '_colorcon_log.ps'
  ps_cont_file = base_name + '_contour_log.ps'
  ps_surf_file = base_name + '_surface_log.ps'
  ps_line_file = base_name + '_lineout_log.ps'
  ps_tier_file = base_name + '_tiered_log.ps'
endelse

; *****************************************************************
; Specify which plots you want (1) or don't want (0):
; *****************************************************************

doShow3D = 0
doSurface = 1
doLineout = 1
doContour = 1
doColorCon = 1

; *****************************************************************
; Specify minimum and/or maximum values for x1 and x2:
; *****************************************************************

; Set auto_scale_min to 1 (default choice) for automatic scaling
;    of x1min and x2min.
; Set auto_scale_max to 1 (default choice) for automatic scaling
;    of x1max and x2max.

; If you chose to set auto_scale_min or auto_scale_max to zero, then
;    you must provide the desired limits.

auto_scale_min = 1
auto_scale_max = 1

;x1min = 0.
;x1max = 2.
;x2min = 0.
;x2max = 0.2

x1min = 0.9
x1max = 1.1
x2min = 0.
x2max = 0.5

; Set a factor (between 0 and 1) specifying which row of data
;    (r=constant or y=constant) that you want for the lineout plot.
r_factor = 0.

; *****************************************************************
; Parse the ascii data file or restore from the binary IDL file
; *****************************************************************

; Check to see if the "restore" file has been created:
spawn, "ls | grep " + restore_file, check_file, /sh
;print, 'The "check"   file is: ', check_file
;print, 'The "restore" file is: ', restore_file

; If the restore file exists, then use it.
if (check_file(0) eq restore_file) then begin

  print, ' '
  print,'Reading from the restore file: ' + restore_file + ' ...'
  restore, filename = restore_file

; Otherwise, parse the text file:
endif else begin

  print, ' '
  print,'Parsing the text file: ' + text_file + ' ...'
  data=read_ascii(text_file)

  print, ' '
  print, 'Here is the size and shape of the raw data:'
  help,data.field1

; *****************************************************************
; Initial manipulation of the data
; *****************************************************************

; Load the raw data into individual arrays.
  z1d =data.field1(0,*)
  r1d =data.field1(1,*)
  ez1d=data.field1(2,*)

  print, ' '
  print, 'z1d, r1d, ez1d are the columns of the raw data:'
  help,z1d
  help,r1d
  help,ez1d
  print, 'z1d(0) z1d(1) z1d(n-1) = ', z1d(0),z1d(1),z1d(n_elements(z1d)-1)
  print, 'r1d(0) r1d(1) r1d(n-1) = ', r1d(0),r1d(1),r1d(n_elements(r1d)-1)

; Extract the unique values for r and z grid points
  ztemp=z1d(sort(z1d))
  z=ztemp(uniq(ztemp))
  rtemp=r1d(sort(r1d))
  r=rtemp(uniq(rtemp))

  nz = n_elements(z)
  nr = n_elements(r)

  print, ' '
  print, 'z and r contain only the unique values of the original arrays:'
  help,z
  help,r
  print, 'nz = ', nz
  print, 'nr = ', nr
  print, 'z(0) z(1) z(', nz-1, ') = ', z(0),z(1),z(nz-1)
  print, 'r(0) r(1) r(', nr-1, ') = ', r(0),r(1),r(nr-1)

; Create a 2-D array that holds the gridded surface data
  print, ' '
  print, 'Creating ez from tri_surf() of the raw data (takes a while)....'
  help, ez1d
  help, z1d
  help, r1d
  print, "max_ez1d = ", max(ez1d)
  print, "min_ez1d = ", min(ez1d)
  nx=nz
  ny=nr
  ez = dblarr(nx,ny)
  for i = 0, nx-1 do begin
        ez(i,*) = ez1d[i*ny:(i+1)*ny-1]
        ;;;for j = 0, ny-1 do begin
        ;;;        ez(i,j) = ez1d[i*ny+j]
        ;;;endfor
  endfor
  print, '  ...done! '
  help,ez
  print, "max_ez = ", max(ez)
  print, "min_ez = ", min(ez)

; Save so IDL doesn't have to repeatedly parse the ASCII file
  save, z,r,ez,nz,nr, filename = restore_file

; *****************************************************************
; Here is the end of the if/then/else construct for parsing.
; *****************************************************************
endelse

; *****************************************************************
; Scale the data so it corresponds to the desired units and set the labels
; *****************************************************************
;
q1_label = '!3k!d' + x1Label + '!n'
q2_label = '!3k!d' + x2Label + '!n'
z_label  = '!3PSD(E!D' + EcomponentLabel + '!N)'
if ( ScaleFlag eq 1 ) then begin
  ;
  ; scale the length using as a c/omega_0 as a length scale
  ; 
  omega_0 = ScaleInput
  lengthScale = 3.0e8/omega_0
  E0 = 0.511e6 / lengthScale
  z = z*lengthScale
  r = r*lengthScale
endif else if (ScaleFlag eq 2) then begin
  ;
  ; scale the length using 1/Kp, Kp is the plasma wave vector
  ; 
  density = ScaleInput
  Kp = 2*acos(-1.0)*9000.0*sqrt(density)/3.0e8
  Ep = 0.511e6 * Kp   
  z = z/Kp
  r = r/Kp
endif else begin
  ;
  ; this is the default case of no scaling 
  ;
  x_label = q1_label + ' (m!d-1!n)'
  y_label = q2_label + ' (m!d-1!n)'
endelse

print, ' '
print, 'After normalization of the z and r arrays:'
print, 'nz = ', nz
print, 'nr = ', nr
print, 'z(0) z(1) z(', nz-1, ') = ', z(0),z(1),z(nz-1)
print, 'r(0) r(1) r(', nr-1, ') = ', r(0),r(1),r(nr-1)

print, ' '
print, 'These are the min and max values of the original data:'

x1min_data = z(0)
x2min_data = r(0)
x1max_data = z(nz-1)
x2max_data = r(nr-1)

help,x1min_data
help,x1max_data
help,x2min_data
help,x2max_data

if (auto_scale_min ne 0) then begin
  x1min = x1min_data
  x2min = x2min_data
endif

if (auto_scale_max ne 0) then begin
  x1max = x1max_data
  x2max = x2max_data
endif

print, ' '
print, 'These are the specified min and max values:'

help,x1min
help,x1max
help,x2min
help,x2max

; *****************************************************************
; Surface plots don't support xrange/yrange, so truncate the data:
; *****************************************************************
if ( (x1min gt x1min_data) or (x2min gt x2min_data) ) then begin
  struct_A = array_cut(z, r, ez, x1min, x2min)
  z  = struct_A.xnew
  r  = struct_A.ynew
  ez = struct_A.znew

  nz = n_elements(z)
  nr = n_elements(r)

  print, ' '
  print, 'After applying the specified x1min and x2min --'
  print, 'nz = ', nz
  print, 'nr = ', nr
  print, 'z(0) z(1) z(', nz-1, ') = ', z(0),z(1),z(nz-1)
  print, 'r(0) r(1) r(', nr-1, ') = ', r(0),r(1),r(nr-1)
endif

if ( (x1max lt x1max_data) or (x2max lt x2max_data) ) then begin
  struct_A = array_cut_max(z, r, ez, x1max, x2max)
  z  = struct_A.xnew
  r  = struct_A.ynew
  ez = struct_A.znew

  nz = n_elements(z)
  nr = n_elements(r)

  print, ' '
  print, 'After applying the specified x1max and x2max --'
  print, 'nz = ', nz
  print, 'nr = ', nr
  print, 'z(0) z(1) z(', nz-1, ') = ', z(0),z(1),z(nz-1)
  print, 'r(0) r(1) r(', nr-1, ') = ', r(0),r(1),r(nr-1)
endif
; *****************************************************************
; Create a 2-D color map appropriate for the surface
; *****************************************************************

; Create a 2D array that specifies the color for each grid point
ez_log = alog(ez)
if (log_plot_flag eq 0) then begin
  ez_color=ez-min(ez)
  ez_color=ez_color/max(ez_color)
  ez_color=ez_color*255.
endif else begin
  ez_color=ez_log-min(ez_log)
  ez_color=ez_color/max(ez_color)
  ez_color=ez_color*255.
endelse

; *****************************************************************
; Loop for rendering 2-D B&W contour plot on screen and to a file
; *****************************************************************

if (doContour eq 1) then begin

; Get a new window
  window_number = !d.window + 1
  print, ' '
  print, 'Contour plot will appear in window ', window_number
  window, window_number
  contour_i = 0
  contour_jump:

; Specify a font that looks great for printing (crappy on screen),
;   or else one that looks OK on the screen (also OK for printing).
  if (!d.name eq 'PS') then begin
    !p.font=1
    !p.charsize=1.6
    !p.charthick=1.5
    if ( ScaleFlag eq 1 ) then begin
      x_label = q1_label + ' (!9w!3!d0!N/c)'
      y_label = q2_label + ' (!9w!3!d0!N/c)'
    endif else if ( ScaleFlag eq 2 ) then begin
      x_label = q1_label + ' (!9w!3!dp!N/c)'
      y_label = q2_label + ' (!9w!3!dp!N/c)'
    endif 
    print, ' '
    print, 'Writing the 2D b&w contour plot to file ' + ps_cont_file
  endif else begin
    !p.font=-1
    !p.charsize=2.0
    if ( ScaleFlag eq 1 ) then begin
      x_label = q1_label + ' (!4x!3!d0!N/c)'
      y_label = q2_label + ' (!4x!3!d0!N/c)'
    endif else if ( ScaleFlag eq 2 ) then begin
      x_label = q1_label + ' (!4x!3!dp!N/c)'
      y_label = q2_label + ' (!4x!3!dp!N/c)'
    endif 
    device,decomposed=0
    print, ' '
    print, 'Rendering the 2D b&w contour plot to the screen...'
  endelse
  
  print, 'min_x1  = ' , min(z)
  print, 'max_x1  = ' , max(z)
  print, 'min_x2  = ' , min(r)
  print, 'max_x2  = ' , max(r)

if (log_plot_flag eq 0) then begin
  contour, ez, z, r, thick=2, /xs, /ys, nlevels=4, xtitle=x_label, ytitle=y_label
endif else begin
  contour, ez_log, z, r, thick=2, /xs, /ys, nlevels=4, xtitle=x_label, ytitle=y_label
endelse


; rendering to screen is done.  here we render to ps file
  if (contour_i eq 0) then begin
    contour_i = 1
    set_plot, 'PS', /copy
    device, filename = ps_cont_file
    goto, contour_jump  
  endif

; here rendering to file is done.  set back to screen defaults
  if (contour_i eq 1) then begin
    device, /close
    set_plot, 'X'
    !p.font=-1
    !p.charsize=2.0
    device,decomposed=0
  endif

endif


; *****************************************************************
; Loop for rendering 2-D color contour plot on screen and to a file
; *****************************************************************

if (doColorCon eq 1) then begin

; Get a new window
  window_number = !d.window + 1
  print, ' '
  print, 'Color contour plot will appear in window ', window_number
  window, window_number
  ccontour_i = 0
  ccontour_jump:

; Load in the STD GAMMA-II color table
  loadct, 5

; Specify a font that looks great for printing (crappy on screen),
;   or else one that looks OK on the screen (also OK for printing).
  if (!d.name eq 'PS') then begin
    !p.font=1
    !p.charsize=1.6
    !p.charthick=1.5
    if ( ScaleFlag eq 1 ) then begin
      x_label = q1_label + ' (!9w!3!d0!N/c)'
      y_label = q2_label + ' (!9w!3!d0!N/c)'
    endif else if ( ScaleFlag eq 2 ) then begin
      x_label = q1_label + ' (!9w!3!dp!N/c)'
      y_label = q2_label + ' (!9w!3!dp!N/c)'
    endif 
    print, ' '
    print, 'Writing the 2D color contour plot to file ' + ps_ccon_file
  endif else begin
    !p.font=-1
    !p.charsize=2.0
    if ( ScaleFlag eq 1 ) then begin
      x_label = q1_label + ' (!4x!3!d0!N/c)'
      y_label = q2_label + ' (!4x!3!d0!N/c)'
    endif else if ( ScaleFlag eq 2 ) then begin
      x_label = q1_label + ' (!4x!3!dp!N/c)'
      y_label = q2_label + ' (!4x!3!dp!N/c)'
    endif 
    device,decomposed=0
    print, ' '
    print, 'Rendering the 2D color contour plot to the screen...'
  endelse

if (log_plot_flag eq 0) then begin
  contour, ez, z, r, thick=2, /xs, /ys, nlevels=100, xtitle=x_label, ytitle=y_label, /fill
endif else begin
  contour, ez_log, z, r, thick=2, /xs, /ys, nlevels=100, xtitle=x_label, ytitle=y_label, /fill
endelse

; rendering to screen is done.  here we render to ps file
  if (ccontour_i eq 0) then begin
    ccontour_i = 1
    set_plot, 'PS', /copy
    device, filename = ps_ccon_file, /color, bits_per_pixel=8
    goto, ccontour_jump  
  endif

; here rendering to file is done.  set back to screen defaults
  if (ccontour_i eq 1) then begin
    device, /close
    set_plot, 'X'
    !p.font=-1
    !p.charsize=2.0
    device,decomposed=0
  endif

endif


; *****************************************************************
; Loop for rendering color surface plot on screen and to a file
; *****************************************************************

if (doSurface eq 1) then begin

; Get a new window
  window_number = !d.window + 1
  print, ' '
  print, 'Color surface plot will appear in window ', window_number
  window, window_number
  surface_i = 0
  surface_jump:

; Load in the STD GAMMA-II color table
  loadct, 5

; Specify a font that looks great for printing (crappy on screen),
;   or else one that looks OK on the screen (also OK for printing).
  if (!d.name eq 'PS') then begin
    !p.font=1
    !p.charsize=1.6
    !p.charthick=1.5
    if ( ScaleFlag eq 1 ) then begin
      x_label = q1_label + ' (!9w!3!d0!N/c)'
      y_label = q2_label + ' (!9w!3!d0!N/c)'
    endif else if ( ScaleFlag eq 2 ) then begin
      x_label = q1_label + ' (!9w!3!dp!N/c)'
      y_label = q2_label + ' (!9w!3!dp!N/c)'
    endif 
    print, ' '
    print, 'Writing the color surface plot to file ' + ps_surf_file
  endif else begin
    !p.font=-1
    !p.charsize=2.0 
    if ( ScaleFlag eq 1 ) then begin
      x_label = q1_label + ' (!4x!3!d0!N/c)'
      y_label = q2_label + ' (!4x!3!d0!N/c)'
    endif else if ( ScaleFlag eq 2 ) then begin
      x_label = q1_label + ' (!4x!3!dp!N/c)'
      y_label = q2_label + ' (!4x!3!dp!N/c)'
    endif 
    device,decomposed=0
    print, ' '
    print, 'Rendering the color surface plot to the screen...'
  endelse

;  xAng = 90;
;  zAng = 0;
  xAng = 50;
  zAng = 30;

if (log_plot_flag eq 0) then begin
  surface, ez, z, r, thick=2, /xs, /ys, ax=xAng, az=zAng, shades=ez_color, $
           xtitle=x_label, ytitle=y_label, ztitle=z_label
endif else begin
  surface, ez, z, r, thick=2, /xs, /ys, ax=xAng, az=zAng, shades=ez_color, $
           xtitle=x_label, ytitle=y_label, ztitle=z_label, /zlog
endelse

; rendering to screen is done.  here we render to ps file
  if (surface_i eq 0) then begin
    surface_i = 1
    set_plot, 'PS', /copy
    device, filename = ps_surf_file, /color, bits_per_pixel=8
    goto, surface_jump  
  endif

; here rendering to file is done.  set back to screen defaults
  if (surface_i eq 1) then begin
    device, /close
    set_plot, 'X'
    !p.font=-1
    !p.charsize=2.0
    device,decomposed=0
  endif

endif


; *****************************************************************
; Repeat simple plot loop for generating fancy 3-tiered plot.
; *****************************************************************

if (doShow3D eq 1) then begin

; Get a new window
  window_number = !d.window + 1
  print, ' '
  print, 'Three-tiered plot will appear in window ', window_number
  window, window_number
  three_tiered_i = 0
  three_tiered_jump:

; Load in the STD GAMMA-II color table
  loadct, 5

; Specify a font that looks great for printing (crappy on screen),
;   or else one that looks OK on the screen (also OK for printing).
  if (!d.name eq 'PS') then begin
    !p.font=1
    !p.charsize=1.6
    !p.charthick=1.5
    if ( ScaleFlag eq 1 ) then begin
      x_label = q1_label + ' (!9w!3!d0!N/c)'
      y_label = q2_label + ' (!9w!3!d0!N/c)'
    endif else if ( ScaleFlag eq 2 ) then begin
      x_label = q1_label + ' (!9w!3!dp!N/c)'
      y_label = q2_label + ' (!9w!3!dp!N/c)'
    endif 
    print, ' '
    print, 'Writing 3-tiered surface/contour plot to file ' + ps_tier_file
  endif else begin
    !p.font=-1
    !p.charsize=2.0
    if ( ScaleFlag eq 1 ) then begin
      x_label = q1_label + ' (!4x!3!d0!N/c)'
      y_label = q2_label + ' (!4x!3!d0!N/c)'
    endif else if ( ScaleFlag eq 2 ) then begin
      x_label = q1_label + ' (!4x!3!dp!N/c)'
      y_label = q2_label + ' (!4x!3!dp!N/c)'
    endif 
    device,decomposed=0
    print, ' '
    print, 'Rendering the 3-tiered surface/contour plot to the screen...'
  endelse

  surface_struct = { shades:ez_color, xtitle:x_label, ytitle:y_label, ztitle:z_label, $
                     xstyle:1, ystyle:1, zstyle:1}
  contour_struct = { nlevels:6, xstyle:1, ystyle:1, zstyle:1}
  show3, ez, z, r, e_surface=surface_struct, e_contour=contour_struct

; rendering to screen is done.  here we render to ps file
  if (three_tiered_i eq 0) then begin
    three_tiered_i = 1
    set_plot, 'PS', /copy
    device, filename = ps_tier_file, /color, bits_per_pixel=8
    goto, three_tiered_jump  
  endif

; here rendering to file is done.  set back to screen defaults
  if (three_tiered_i eq 1) then begin
    device, /close
    set_plot, 'X'
    !p.font=-1
    !p.charsize=2.0
    device,decomposed=0
  endif

endif

; *****************************************************************
; Repeat simple plot loop for generating 2-D lineout plots.
; *****************************************************************

if (doLineout eq 1) then begin

; First, grab the desired row of data (here it is along the r=0 axis)
; Specify which row (fixed value of r) of grid points you will
;   want to use for the lineout plot
  r_row = fix(nr*r_factor)
  ez_line = ez(*,r_row)

  print, ' '
  print, 'r_row = ', r_row
  help, ez_line

; Put the plot into a new window
  window_number = !d.window + 1
  print, ' '
  print, 'Line plot will appear in window ', window_number
  window, window_number
  lineout_i = 0
  lineout_jump:

; Load in the STD GAMMA-II color table
  loadct, 5

; Specify a font that looks great for printing (crappy on screen),
;   or else one that looks OK on the screen (also OK for printing).
  if (!d.name eq 'PS') then begin
    !p.font=1
    !p.charsize=1.6
    !p.charthick=1.5
    if ( ScaleFlag eq 1 ) then begin
      x_label = q1_label + ' (!9w!3!d0!N/c)'
      y_label = q2_label + ' (!9w!3!d0!N/c)'
    endif else if ( ScaleFlag eq 2 ) then begin
      x_label = q1_label + ' (!9w!3!dp!N/c)'
      y_label = q2_label + ' (!9w!3!dp!N/c)'
    endif 
    print, ' '
    print, 'Writing the 2D lineout plot to file ' + ps_line_file
  endif else begin
    !p.font=-1
    !p.charsize=2.0
    if ( ScaleFlag eq 1 ) then begin
      x_label = q1_label + ' (!4x!3!d0!N/c)'
      y_label = q2_label + ' (!4x!3!d0!N/c)'
    endif else if ( ScaleFlag eq 2 ) then begin
      x_label = q1_label + ' (!4x!3!dp!N/c)'
      y_label = q2_label + ' (!4x!3!dp!N/c)'
    endif 
    device,decomposed=0
    print, ' '
    print, 'Rendering the 2D lineout plot for the screen...'
  endelse

if (log_plot_flag eq 0) then begin
  plot, z, ez_line, thick=2, /xs, xtitle=x_label, ytitle=z_label, xrange=[x1min,x1max]
endif else begin
  plot_io, z, ez_line, thick=2, /xs, xtitle=x_label, ytitle=z_label, xrange=[x1min,x1max]
endelse

; rendering to screen is done.  here we render to ps file
  if (lineout_i eq 0) then begin
    lineout_i = 1
    set_plot, 'PS', /copy
    device, filename = ps_line_file, /color, bits_per_pixel=8
    goto, lineout_jump  
  endif

; here rendering to file is done.  set back to screen defaults
  if (lineout_i eq 1) then begin
    device, /close
    set_plot, 'X'
    !p.font=-1
    !p.charsize=2.0
    device,decomposed=0
  endif

endif


; *****************************************************************
; Final clean-up
; *****************************************************************

; Stop here so that all variables will still be in scope.
stop

; All done.
end





; *****************************************************************
; checkComponent procedure
; *****************************************************************

pro checkComponent, componentLabel, component

  CASE ComponentLabel OF
    ; if componentLabel is 'x' 
    'x': print, "Setting "+component+" label to "+ComponentLabel

    ; 'y'
    'y': print, "Setting "+component+" label to "+ComponentLabel

    ; 'r'
    'r': print, "Setting "+component+" label to "+ComponentLabel
                         
    ; 'z'                
    'z': print, "Setting "+component+" label to "+ComponentLabel

    ; no matches => print warning
  ELSE: print, "WARNING: Component label is not in the set (x, y, r, z)!?"
  ENDCASE
end