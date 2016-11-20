## UWG_Matlab
Urban Weather Generator (http://urbanmicroclimate.scripts.mit.edu/uwg.php)

Repository for keeping versions of UWG Matlab code based on Bruno Bueno's work with Leslie Norford from MIT.

### Known Issues
All inquiries generally fall into two categories:
* Matlab Runtime - when running the executable version of the file, the correct Matlab Runtime version is also required, which has changed with the UWG updates. The latest compiled version (4.1) was compiled in with Matlab R2015b in Windows 64bit environment and requires Matlab Runtime 9.0. The installation file will prompt to identify and download the correct version if not already installed. For other operating systems, the Matlab code should be re-packaged to generate the correct executable version as needed.

* Layer Thickness - The UWG uses explicit time-step and thus having a wall or roof layer such as membrane that is too thin, or a layer will high thermal conductivity (e.g. metal decking) will result in fatal error. These layers should be incorporated into a single layer that is representative of the overall optical property, thermal conductivity and thermal capacitance. 

### Contact
Jiachen Mao <maoj@mit.edu>
Leslie Keith Norford <lnorford@mit.edu>

### History
* June, 2016 - UWG updated to version 4.1, based on Joseph Yang's master's thesis (2016). Changes include addition of three input file format (XML, Matlab, Excel), and update of the internal algorithm. 
* Oct, 2015 - Github Repository created by Joseph Yang with latest version of UWG, based on Aiko Akano's master's thesis.
