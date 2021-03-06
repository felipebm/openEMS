% example demonstrating the use of a stripline terminated by the pml
% (c) 2013 Thorsten Liebig

close all
clear
clc

%% setup the simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
physical_constants;
unit = 1e-6; % specify everything in um
SL_length = 50000;
SL_width = 520;
SL_height = 500;
substrate_thickness = SL_height;
substrate_epr = 3.66;
f_max = 7e9;

%% setup FDTD parameters & excitation function %%%%%%%%%%%%%%%%%%%%%%%%%%%%
FDTD = InitFDTD();
FDTD = SetGaussExcite( FDTD, f_max/2, f_max/2 );
BC   = {'PML_8' 'PML_8' 'PMC' 'PMC' 'PEC' 'PEC'};
FDTD = SetBoundaryCond( FDTD, BC );

%% setup CSXCAD geometry & mesh %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CSX = InitCSX();
resolution = c0/(f_max*sqrt(substrate_epr))/unit /50; % resolution of lambda/50
mesh.x = SmoothMeshLines( [-SL_length/2 0 SL_length/2], resolution, 1.5 ,0 );
mesh.y = SmoothMeshLines( [0 SL_width/2+[-resolution/3 +resolution/3*2]/4], resolution/4 , 1.5 ,0);
mesh.y = SmoothMeshLines( [-10*SL_width -mesh.y mesh.y 10*SL_width], resolution, 1.3 ,0);
mesh.z = linspace(0,substrate_thickness,5);
mesh.z = sort(unique([mesh.z -mesh.z]));
CSX = DefineRectGrid( CSX, unit, mesh );

%% substrate
CSX = AddMaterial( CSX, 'RO4350B' );
CSX = SetMaterialProperty( CSX, 'RO4350B', 'Epsilon', substrate_epr );
start = [mesh.x(1),   mesh.y(1),   mesh.z(1)];
stop  = [mesh.x(end), mesh.y(end), mesh.z(end)];
CSX = AddBox( CSX, 'RO4350B', 0, start, stop );

%% SL port
CSX = AddMetal( CSX, 'PEC' );
portstart = [ mesh.x(1), -SL_width/2, 0];
portstop  = [ 0,         SL_width/2, 0];
[CSX,port{1}] = AddStripLinePort( CSX, 999, 1, 'PEC', portstart, portstop, SL_height, 'x', [0 0 -1], 'ExcitePort', true, 'FeedShift', 10*resolution, 'MeasPlaneShift',  SL_length/3);

portstart = [mesh.x(end), -SL_width/2, 0];
portstop  = [0          ,  SL_width/2, 0];
[CSX,port{2}] = AddStripLinePort( CSX, 999, 2, 'PEC', portstart, portstop, SL_height, 'x', [0 0 -1], 'MeasPlaneShift',  SL_length/3 );

%% write/show/run the openEMS compatible xml-file
Sim_Path = ['tmp_' mfilename];
Sim_CSX = 'stripline.xml';

[status, message, messageid] = rmdir( Sim_Path, 's' ); % clear previous directory
[status, message, messageid] = mkdir( Sim_Path ); % create empty simulation folder

WriteOpenEMS( [Sim_Path '/' Sim_CSX], FDTD, CSX );
CSXGeomPlot( [Sim_Path '/' Sim_CSX] );
RunOpenEMS( Sim_Path, Sim_CSX );

%% post-processing
close all
f = linspace( 1e6, f_max, 1601 );
port = calcPort( port, Sim_Path, f, 'RefImpedance', 50);

s11 = port{1}.uf.ref./ port{1}.uf.inc;
s21 = port{2}.uf.ref./ port{1}.uf.inc;

plot(f/1e9,20*log10(abs(s11)),'k-','LineWidth',2);
hold on;
grid on;
plot(f/1e9,20*log10(abs(s21)),'r--','LineWidth',2);
legend('S_{11}','S_{21}');
ylabel('S-Parameter (dB)','FontSize',12);
xlabel('frequency (GHz) \rightarrow','FontSize',12);
ylim([-50 2]);

