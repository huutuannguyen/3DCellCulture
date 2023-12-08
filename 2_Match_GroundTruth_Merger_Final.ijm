/*
 * Fiji ImageJ Macro for groundtruth merger
 * Purpose: This macro merges the grouth truth tiled image into the original mosaic image 
 * Version: 1.0
 * Author: Huu Tuan Nguyen
 * Date: 05 Dec 2023
 * License: MIT License
 * Compatibility: Tested on Fiji ImageJ version [Version]. May not be compatible with older versions.
 * 
 * Change Log:
 * - Version 1.0: Initial version.
 */
 // Configuration Parameters
height=200;
width=200;
function mergeMatch(input, groundTruthFolder) {
	tile_Dim_Z=1;
	frames=1;
	cell_List= getFileList(input+"_tiles"+File.separator+"Result"+File.separator);
	for (j=0; j < cell_List.length; j++) {
		cell_lv1_List= getFileList(input+"_tiles"+File.separator+"Result"+File.separator+cell_List[j]);
		for (l=0; l < cell_lv1_List.length; l++) {
			suffix="MatchingMethodGroundTruthCC.tif";			//cancer cells
			if(endsWith(cell_lv1_List[l], suffix)) {
				open(input+"_tiles/Result/"+cell_List[j]+cell_lv1_List[l]);
				tumorCellImage=getTitle();
			}
			suffix="MatchingMethodGroundTruthFB.tif";			//fibroblast
			if(endsWith(cell_lv1_List[l], suffix)) {
				open(input+"_tiles/Result/"+cell_List[j]+cell_lv1_List[l]);
				FibroblastImage=getTitle();
			}
		}
		run("Merge Channels...", "c1=["+tumorCellImage+"] c2=["+FibroblastImage+"] create keep ignore");
		Stack.setDisplayMode("composite");
		Stack.setActiveChannels("11");
		run("Green");
		resetMinAndMax();
		run("Red");
		resetMinAndMax();
		run("Z Project...", "projection=[Max Intensity]");			
		run("Canvas Size...", "width="+width+" height="+height+" position=Top-Left zero"); // to avoid images at the end that does not have dimension widthxheight
		saveAs("PNG", groundTruthFolder+substring(tumorCellImage, 0, lengthOf(tumorCellImage)-21)+"MAX.PNG");
		selectImage(tumorCellImage);
		close();
		selectImage(FibroblastImage);
		close();
		run("Close All");
	}
}
//Automatic stitching for recapitulating the original image
function stitching(input, groundTruthFolder) {
	filestring=File.openAsString(input+"tile_info.txt");
	rows=split(filestring, "\n");
	x=newArray(rows.length);
	y=newArray(rows.length);
	columns=split(rows[1],";");
	tileNumberX=parseInt(parseFloat(columns[0]+0.49));
	tileNumberY=parseInt(parseFloat(columns[1]+0.49)); //round to the closest integer
	waitForUser(tileNumberX+"  "+tileNumberY);
	tile_Dim_X=parseInt(columns[2]);
	tile_Dim_Y=parseInt(columns[3]);
	overlap=parseInt(columns[4])/tile_Dim_Y*100;
	cell_List= getFileList(groundTruthFolder);
	run("Grid/Collection stitching", "type=[Grid: row-by-row] order=[Right & Down                ] grid_size_x="+tileNumberX+" grid_size_y="+tileNumberY+" tile_overlap="+overlap+" first_file_index_i=0 directory=["+groundTruthFolder+"] file_names=["+substring(cell_List[0], 0, cell_List[0]-23)+"00{ii}_MatchingMeMAX.PNG] output_textfile_name=TileConfiguration.txt fusion_method=[Max. Intensity] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
	saveAs("Tiff", groundTruthFolder+"reconstructed_merged"+substring(ROI_List[i], 0, lengthOf(ROI_List[i])-1)+".tif");
	run("Z Project...", "projection=[Max Intensity]");
	makeRectangle(0, 0, original_Dim_X, original_Dim_Y);
	run("Duplicate...", "duplicate");
	saveAs("PNG", groundTruthFolder+"MAX_reconstructed_merged"+substring(ROI_List[i], 0, lengthOf(ROI_List[i])-1)+".PNG");
	run("Close All");
}

macro batchProcessing {
	waitForUser("Please select the image folder containing all tiles (all ROI folder)");
	input = getDirectory("Folder");
	ROI_List= getFileList(input);					//ROI
	i=0;
		for (i=0; i < ROI_List.length; i++) {
			tile_Dim_Z=1;
			frames=1;
			suffix="/";
			if(endsWith(ROI_List[i], suffix)) {
				groundTruthFolder=input+ROI_List[i]+"MatchGroundTruthFolder"+File.separator;
				File.makeDirectory(groundTruthFolder);
				mergeMatch(input+ROI_List[i], groundTruthFolder);
			}
		}
	waitForUser("Finish");
}