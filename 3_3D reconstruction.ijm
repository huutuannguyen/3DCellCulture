// This will use the csv file to recreate the processed image
/*
 * Fiji ImageJ Macro for 3D Image reconstruction/recaptitulation
 * Purpose: This macro recaptitulates the original stained images using cells classified by CNN.
 * Version: 1.0
 * Author: Huu Tuan Nguyen
 * Date: 05 Dec 2023
 * License: MIT License
 * Compatibility: Tested on Fiji ImageJ version [Version]. May not be compatible with older versions.
 * 
 * Change Log:
 * - Version 1.0: Initial version.
 */
function processFolder(input) {
	ROI_List= getFileList(input);					//ROI
	i=0;
	for (i=0; i < ROI_List.length; i++) {
		tile_Dim_Z=1;
		frames=1;
		suffix="/";
		if(endsWith(ROI_List[i], suffix)) {
	 	ROI_lv1=getFileList(input+ROI_List[i]);// ROI level 1 to find the ROI.tif
		for (m=0; m < ROI_lv1.length; m++) {
			suffix="tif";
			if(endsWith(ROI_lv1[m], suffix)) {
				open(input+ROI_List[i]+ROI_lv1[m]);
				rename("original_im");
				getDimensions(tile_Dim_X, tile_Dim_Y, channels, tile_Dim_Z, frames);
				Stack.setDisplayMode("composite");
				Stack.setActiveChannels("01100");
				Stack.setChannel(2);
				run("Green");
				resetMinAndMax();
				Stack.setChannel(3);
				run("Red");
				resetMinAndMax();
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("PNG", input+substring(ROI_List[i], 0, lengthOf(ROI_List[i])-1)+File.separator+"original_merged"+substring(ROI_List[i], 0, lengthOf(ROI_List[i])-1)+".PNG");
			}
		}
	
		tile_Dim_X=200;
		tile_Dim_Y=200;
		cell_List= getFileList(input+substring(ROI_List[i], 0, lengthOf(ROI_List[i])-1)+File.separator+"_tiles"+File.separator+"Result"+File.separator);
		for (j=0; j < cell_List.length; j++) {
			newImage("Fibroblast_recon"+substring(cell_List[j], 0, lengthOf(cell_List[j])-1), "8-bit grayscale-mode", tile_Dim_X, tile_Dim_Y, 1, tile_Dim_Z, frames);
			newImage("Cancer_recon"+substring(cell_List[j], 0, lengthOf(cell_List[j])-1), "8-bit grayscale-mode", tile_Dim_X, tile_Dim_Y, 1, tile_Dim_Z, frames);
			close("original_im");
			suffix="/";
			if(endsWith(cell_List[j], suffix)) {
				cell_lv1_List= getFileList(input+substring(ROI_List[i], 0, lengthOf(ROI_List[i])-1)+File.separator+"_tiles"+File.separator+"Result"+File.separator+cell_List[j]);
			for (l=0; l < cell_lv1_List.length; l++) {
				suffix="/";	
				if(endsWith(cell_lv1_List[l], suffix)) {
					if (File.exists(input+ROI_List[i]+"_tiles/Result/"+cell_List[j]+cell_lv1_List[l]+"the_csv_file.csv")) {
						open(input+ROI_List[i]+"_tiles/Result/"+cell_List[j]+cell_lv1_List[l]+"the_csv_file.csv");
						fibroblastStatus=getResult("Fibroblast",1);
						cancerCellStatus=getResult("Cancer",1);
						cell_lv2_List= getFileList(input+substring(ROI_List[i], 0, lengthOf(ROI_List[i])-1)+File.separator+"_tiles"+File.separator+"Result"+File.separator+cell_List[j]+cell_lv1_List[l]);
						for (k=0; k < cell_lv2_List.length; k++) {		
							if(endsWith(cell_lv2_List[k], "zip")) {
								run("3D Manager");
								Ext.Manager3D_Load(input+substring(ROI_List[i], 0, lengthOf(ROI_List[i])-1)+File.separator+"_tiles"+File.separator+"Result"+File.separator+cell_List[j]+cell_lv1_List[l]+cell_lv2_List[k]);
							}
						}
					if (fibroblastStatus>0){
						selectImage("Fibroblast_recon"+substring(cell_List[j], 0, lengthOf(cell_List[j])-1));
						Ext.Manager3D_Select(0);
						Ext.Manager3D_FillStack(255, 255, 255);
	//										waitForUser("check point 4a"+cell_List[j]+cell_lv1_List[l]);
					}
						else {
						selectImage("Cancer_recon"+substring(cell_List[j], 0, lengthOf(cell_List[j])-1));
						Ext.Manager3D_Select(0);
						Ext.Manager3D_FillStack(255, 255, 255);
	//										waitForUser("check point 4b"+cell_List[j]+cell_lv1_List[l]);
	
						}
						Ext.Manager3D_SelectAll();
						Ext.Manager3D_Delete();
	
								close("the_csv_file.csv");
					}
				}
				run("Clear Results");
			}
			}
			run("Merge Channels...", "c1=[Cancer_recon"+substring(cell_List[j], 0, lengthOf(cell_List[j])-1)+"] c2=[Fibroblast_recon"+substring(cell_List[j], 0, lengthOf(cell_List[j])-1)+"] create keep ignore");
			saveAs("Tiff", input+substring(ROI_List[i], 0, lengthOf(ROI_List[i])-1)+File.separator+"reconstructed_merged"+substring(cell_List[j], 0, lengthOf(cell_List[j])-1)+".tif");
			Stack.setDisplayMode("composite");
			Stack.setActiveChannels("01100");
			run("Green");
			resetMinAndMax();
			run("Red");
			resetMinAndMax();
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("PNG", input+substring(ROI_List[i], 0, lengthOf(ROI_List[i])-1)+File.separator+"original_merged"+substring(cell_List[j], 0, lengthOf(cell_List[j])-1)+".PNG");
			selectImage("Fibroblast_recon"+substring(cell_List[j], 0, lengthOf(cell_List[j])-1));
			close();
			selectImage("Cancer_recon"+substring(cell_List[j], 0, lengthOf(cell_List[j])-1));
			close();
			}
		}
	run("Close All");
	}
}

macro batchProcessing {
waitForUser("Please select the image folder containing all ROI of a sample that contain the origial oib image");
input = getDirectory("Folder");
processFolder(input);
waitForUser("Finish");
}