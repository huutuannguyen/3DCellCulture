/*
 * Fiji ImageJ Macro for 3D Image Segmentation and Tiling
 * Purpose: This macro segments images into tiles containing single cells.
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
var tileDimensionX=200;
var tileDimensionY=200;
// Main function to process images using seed method, i
function UsingSeed(imageName,subExport, img){	
	selectImage(imageName);
	method="Default";
	//Code for proceeding Reflection image or other images
	if (imageName=="reflectionImage") {
		imageCalculator("Average create stack", "Nuclei_blur", imageName);
		run("8-bit");
		//waitForUser("reflection image");
		run("Gaussian Blur 3D...", "x=3 y=3 z=1");
		run("Morphological Filters (3D)", "operation=Dilation element=Ball x-radius=2 y-radius=2 z-radius=2");		// increase the size of each cell due to the gradient eat to each cell
		run("Gradient (3D)", "use");
		rename("Gradient");
		method="Huang";
	}
	else{
		selectImage(imageName);
		run("Duplicate...", "duplicate");
		run("8-bit");
		run("Gaussian Blur 3D...", "x=5 y=5 z=3");
		run("Morphological Filters (3D)", "operation=Dilation element=Ball x-radius=2 y-radius=2 z-radius=2");
		run("Gradient (3D)", "use");
		rename("Gradient");
		run("Gaussian Blur 3D...", "x=1 y=1 z=1");
				//Threshold method of choice based on signal intensity of the Fibroblast or tumor cell channel
		if (imageName=="Fibroblast") {
			method="Huang";
		}else {
			method="Default";}
		}
		selectImage(imageName);
		run("Duplicate...", "duplicate");
		setAutoThreshold(method+" dark stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method="+method+" background=Dark black");
		if (imageName=="reflectionImage") {
			run("Trainable Weka Segmentation 3D");
			wait(500);
			call("trainableSegmentation.Weka_Segmentation.loadClassifier", "D:\\MIT\\image processing plugins\\Nicholas 3D AI\\classifier_20x_new.model");
			call("trainableSegmentation.Weka_Segmentation.getResult");
			run("8-bit");			
			run("Despeckle", "stack");
			run("Convert to Mask", "method=Default background=Light calculate black");
			run("Dilate (3D)", "iso=255");
			run("Dilate (3D)", "iso=255");
		}
		run("Dilate (3D)", "iso=255");
		run("3D Fill Holes");
		rename("Mask");
		run("Clear Results");
		run("Marker-controlled Watershed", "input=Gradient marker=seeds mask=Mask binary calculate use");
		rename("Segmented"+imageName);
		run("8-bit");
		if (imageName=="reflectionImage") {run("3D Exclude Borders", " ");}
		run("Color Balance...");
		resetMinAndMax();
		noBorderIm=getTitle();
		run("Z Project...", "projection=[Max Intensity]");
		rename("Max_project");
		run("Measure");
		checkIntensity=getResult("Mean", 0);
		selectImage("Max_project");
		close();
		run("Clear Results");
		selectImage(noBorderIm);
		if (checkIntensity>0) {
		run("3D Manager");
		Ext.Manager3D_AddImage();
		}
		run("8-bit");
		run("3D Fill Holes");
		saveAs("Tiff", subExport+substring(img,0,lengthOf(img)-4)+"Segmented"+imageName);			// delete border for reflection image only
		selectImage("Gradient");
		close();
		selectImage("Mask");
		close();
}

function isolateCell(img0,i, width, height, slices) {
	newImage("mask","8-bit black" , width, height, slices);
	run("3D Manager");
	Ext.Manager3D_Select(i);
	Ext.Manager3D_FillStack(255, 255, 255);
	run("Morphological Filters (3D)", "operation=Dilation element=Ball x-radius=3 y-radius=3 z-radius=3");
	run("Morphological Filters (3D)", "operation=Erosion element=Ball x-radius=2 y-radius=2 z-radius=2");
	run("Select None");
	run("Divide...", "value=255.000 stack");
	rename("openedMask");
	selectImage(img0);
	run("Select None");
	run("Duplicate...", "duplicate");
	img2=getTitle();
	run("Split Channels");
	imageCalculator("Multiply create stack", "C1-"+img2,"openedMask");
	rename("channel_1_Masked");
	imageCalculator("Multiply create stack", "C2-"+img2,"openedMask");
	rename("channel_2_Masked");
	imageCalculator("Multiply create stack", "C3-"+img2,"openedMask");
	rename("channel_3_Masked");
	imageCalculator("Multiply create stack", "C4-"+img2,"openedMask");
	rename("channel_4_Masked");
	imageCalculator("Multiply create stack", "C5-"+img2,"openedMask");
	rename("channel_5_Masked");
	run("Merge Channels...", "c1=[channel_1_Masked] c2=[channel_2_Masked] c3=[channel_3_Masked] c4=[channel_4_Masked] c5=[channel_5_Masked] create");
	rename("merged_cells"+i);
	selectImage("mask");
	close();
	selectImage("mask-Dilation");
	close();
	selectImage("openedMask");
	close();
	selectImage("C1-"+img2);
	close();
	selectImage("C2-"+img2);
	close();
	selectImage("C3-"+img2);
	close();
	selectImage("C4-"+img2);
	close();
	selectImage("C5-"+img2);
	close();
}
//Automatic processing within the selected folder
function processFolder(input, suffix, export, f) {
	list= getFileList(input);
	i=0;
	for (i=0; i < list.length; i++) {
		if(endsWith(list[i], suffix)) {
			run("Collect Garbage");
			open(input+File.separator+list[i]);
			img0=getTitle();
			subExport=export+substring(img0,0,lengthOf(img0)-4)+File.separator;
			File.makeDirectory(subExport);
			cellSegmentation (img0, subExport, f);
		}
		run("Clear Results");
	}
}
//Function for cell segmentation
function cellSegmentation (img0, subExport, f) {
	selectImage(img0);
	run("Duplicate...", "duplicate");
	img=getTitle();
	run("3D Manager");
	Ext.Manager3D_SelectAll();
	Ext.Manager3D_Delete();
	selectImage(img);
	run("8-bit");
	run("Split Channels");
	selectImage("C1-"+img);
	run("Duplicate...", "duplicate");
	rename("Nuclei_thresholded");
	run("Duplicate...", "duplicate");
	rename("Nuclei_blur");
	run("Gaussian Blur 3D...", "x=3 y=3 z=1");
	run("Extended Min & Max 3D", "operation=[Extended Maxima] dynamic=5 connectivity=6");
	run("3D Fill Holes");
	rename("seeds");
	selectImage("Nuclei_thresholded");
	run("Convert to Mask", "method=Default background=Dark calculate black");
	run("Despeckle", "stack");
	selectImage("C4-"+img);
	rename("reflectionImage");
	UsingSeed("reflectionImage",subExport, img);
	run("3D Manager");
	Ext.Manager3D_Count(nb_obj); 
	selectImage("C2-"+img);
	rename("Fibroblast");
	UsingSeed("Fibroblast",subExport, img);
	selectImage("C5-"+img);
	close();
	selectImage("C1-"+img);
	close();
	selectImage(substring(img,0,lengthOf(img)-4)+"SegmentedFibroblast.tif");					
	run("Convert to Mask", "method=Li background=Dark calculate black");
	selectImage("C3-"+img);
	run("3D Manager");
	Ext.Manager3D_Count(nb_Fb); 
	rename("CancerCells");
	UsingSeed("CancerCells",subExport, img);
	run("3D Manager");
	Ext.Manager3D_Count(nb_CC); 
	Ext.Manager3D_SelectAll();
	Ext.Manager3D_Save(subExport+"Segmented"+substring(img0,0,lengthOf(img0)-4)+"Roi3D.zip");
	selectImage(substring(img,0,lengthOf(img)-4)+"SegmentedCancerCells.tif");
	run("Select None");
	run("Convert to Mask", "method=Li background=Dark calculate black");
	selectImage("CancerCells");
	run("Duplicate...", "duplicate");
	setAutoThreshold("Default dark stack");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Defaut background=Dark black");
	rename("CCsubstract");
	imageCalculator("Subtract stack", substring(img,0,lengthOf(img)-4)+"SegmentedFibroblast.tif","CCsubstract"); // substract autofluorescence of red channel in the green channel
	selectImage(img0);
	getDimensions(width, height, channels, slices, frames);
	newImage("intensityGroundTruthFib","8-bit black" , width, height, slices);
	newImage("intensityGroundTruthCC","8-bit black" , width, height, slices);
	newImage("matchGroundTruthFib","8-bit black" , width, height, slices);
	newImage("matchGroundTruthCC","8-bit black" , width, height, slices);
	setBatchMode(true);
	for (i=0;i<nb_obj;i++) {
		isACell=false;
		run("Collect Garbage");
		run("Clear Results");
		run("3D Manager");
		Ext.Manager3D_Measure3D(i, "Vol", cellVolume);
		selectImage("Nuclei_thresholded");
		Ext.Manager3D_Quantif3D(i, "IntDen", nucleiIntDen);
		if ((cellVolume>15) && (cellVolume<60000)&& (nucleiIntDen>10000)){
			isACell=true;
		}
		if (isACell){			//Filter all ROIs that do not have a sufficient volume or a nucleus
			isolateCell(img0,i, width, height, slices);
			selectImage(substring(img,0,lengthOf(img)-4)+"SegmentedFibroblast.tif");				// measure the ratio between fibroblast and tumor cells based on the thresholded fibroblast image, different than the groundtruth based on actua segmetned fibroblast
			run("3D Manager");
			Ext.Manager3D_Quantif3D(i,"Mean",F);
			selectImage(substring(img,0,lengthOf(img)-4)+"SegmentedCancerCells.tif");
			run("3D Manager");
			Ext.Manager3D_Quantif3D(i,"Mean",C);
			selectImage("merged_cells"+i);
			segAccuracy=0;
			imax=0;
			if (F/(F+C)>0.5) {
			selectImage("intensityGroundTruthFib");
			run("3D Manager");
			Ext.Manager3D_Select(i);
			Ext.Manager3D_FillStack(255, 255, 255);
		}
		else {		
			selectImage("intensityGroundTruthCC");
			run("3D Manager");
			Ext.Manager3D_Select(i);
			Ext.Manager3D_FillStack(255, 255, 255);
		}
		for (i1=nb_obj;i1<nb_CC;i1++) {
			run("Collect Garbage");
			Ext.Manager3D_Coloc2(i,i1,coloc1,coloc2,surf); // render coloc1 and coloc2 the percentage of colocalization
			if (coloc1>segAccuracy) {
				segAccuracy=coloc1;				// maximum value of overlap
				imax=i1;
			}
		}
		if (imax>0) {
		selectImage("Nuclei_thresholded");
		Ext.Manager3D_Quantif3D(imax, "IntDen", benchmarkNucleusIntDen);
		if (benchmarkNucleusIntDen>1000) {				//Select only benchmark cells having nuclei
			selectImage("merged_cells"+i);
			cellFolder=subExport+substring(img0,0,lengthOf(img0)-4)+"cell"+i+File.separator;
			File.makeDirectory(cellFolder);
			selectImage("merged_cells"+i);
			if ((width<tileDimensionX)||(height<tileDimensionY))
				run("Canvas Size...", "width="+tileDimensionX+" height="+tileDimensionY+" position=Top-Left zero"); // to avoid images at the end that does not have dimension widthxheight
			saveAs("Tiff", cellFolder+substring(img0,0,lengthOf(img0)-4)+"_cell"+i+"_"+F/(F+C)+"Fb"+C/(F+C)+"Tc_accuracy"+segAccuracy+"index"+imax+".tif"); // F/F+C is the percentage of fibroblast and C/(F+C) is the percentage of tumor cells
			close();
			run("3D Manager");
			Ext.Manager3D_Select(i);
			Ext.Manager3D_Save(cellFolder+"_cell"+i+".zip");
			isolateCell(img0,imax, width, height, slices);
			selectImage("merged_cells"+imax);
			celltype="";
			if (imax>(nb_Fb-1)) {
				celltype="cancerCells";	
				selectImage("matchGroundTruthCC");
				run("3D Manager");
				Ext.Manager3D_Select(imax);
				Ext.Manager3D_FillStack(255, 255, 255);
			}
			else {
				celltype="fibroblast";
				selectImage("matchGroundTruthFib");
				run("3D Manager");
				Ext.Manager3D_Select(imax);
				Ext.Manager3D_FillStack(255, 255, 255);
			}
			selectImage("merged_cells"+imax);
			if ((width<tileDimensionX)||(height<tileDimensionY))
				run("Canvas Size...", "width="+tileDimensionX+" height="+tileDimensionY+" position=Top-Left zero"); // to avoid images at the end that does not have dimension widthxheight
			saveAs("Tiff", cellFolder+substring(img0,0,lengthOf(img0)-4)+"_groundTruthCell"+imax+"cell type"+celltype+".tif");
			close();
		}else {
			selectImage("merged_cells"+i);
			close();
		}
		print(f, substring(img0,0,lengthOf(img0)-4)+";"+nb_obj+";"+ nb_Fb+";"+ nb_CC+";"+i+";"+F/(F+C)+";"+C/(F+C)+";"+segAccuracy+";"+imax);
		}
		}
	}
	setBatchMode(false);
	selectImage("intensityGroundTruthFib");
	saveAs("Tiff", subExport+substring(img0,0,lengthOf(img0)-4)+"_IntensityMethodGroundTruthFB.tif");
	selectImage("intensityGroundTruthCC");
	saveAs("Tiff", subExport+substring(img0,0,lengthOf(img0)-4)+"_IntensityMethodGroundTruthCC.tif");
	selectImage("matchGroundTruthFib");
	saveAs("Tiff", subExport+substring(img0,0,lengthOf(img0)-4)+"_MatchingMethodGroundTruthFB.tif");
	selectImage("matchGroundTruthCC");
	saveAs("Tiff", subExport+substring(img0,0,lengthOf(img0)-4)+"_MatchingMethodGroundTruthCC.tif");
	run("Close All");
	}
	// Starting point of the macro
macro batchProcessing {
	suffix=".tif"
	waitForUser("Please select the folder having saved tiles");
	input = getDirectory("Folder");
	export=input+"Result"+File.separator;
	File.makeDirectory(export);
	f = File.open(input+"cellInfo.txt"); 
	print(f, "File_name; Total_cell_number; Fibroblasts_number; Tumorcells_number;cell;Fb%;Tc%, %accuracy; groundTruth_index");
	processFolder(input, suffix, export, f);
	waitForUser("Finish");
}
