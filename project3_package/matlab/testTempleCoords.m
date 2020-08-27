% A test script using templeCoords.mat
%
% Write your code here
%

%% 1. Load images and correspondences
im1 = imread('../data/im1.png');
im2 = imread('../data/im2.png');
corresp = load('../data/someCorresp.mat');

%% 2. Run eightpoint to compute fundamental matrix
F = eightpoint(corresp.pts1, corresp.pts2, corresp.M);
% displayEpipolarF(im1, im2, F);

%% 3. Run epipolarCorrespondences on points in img1 to get points in img2
coords = load('../data/templeCoords.mat');
coords.pts2 = epipolarCorrespondence(im1, im2, F, coords.pts1);
% epipolarMatchGUI(im1, im2, F);

%% 4. Load intrisincs.mat and compute essential matrix
intrinsics = load('../data/intrinsics.mat');
E = essentialMatrix(F, intrinsics.K1, intrinsics.K2);


%% 5. Compute camera projection matrices P1, and P2 by camera2
extrinsic1 = [eye(3), zeros(3, 1)];
P1 = intrinsics.K1 * extrinsic1;

% 4 candidates
extrinsic2s = camera2(E);
P2s = zeros(size(extrinsic2s));
for i = 1:4
    P2s(:, :, i) = intrinsics.K2 * extrinsic2s(:, :, i);
end

%% 6. Run triangulate on the 4 candidates
[P2, pts3d, correct_idx] = findExtrinsic2(P1, P2s, coords.pts1, coords.pts2);

% Re-projection error using someCorresp
[err1, err2] = reprojectTriangulated(P1, P2, coords.pts1, coords.pts2, pts3d);
disp('rproj_error(pts1)'); disp(err1);
disp('rproj_error(pts2)'); disp(err2);
 
%% 7. Plot 3D point correspondences using plot3
plot3(pts3d(:, 1), pts3d(:, 3), -pts3d(:, 2), '.'); axis equal

%% 8. Save computed rotation matrix and translation
R1 = extrinsic1(:, 1:3);
t1 = extrinsic1(:, 4);
R2 = extrinsic2s(:, 1:3, correct_idx);
t2 = extrinsic2s(:, 4, correct_idx);

% save extrinsic parameters for dense reconstruction
save('../data/extrinsics.mat', 'R1', 't1', 'R2', 't2');

%% Find the correct P2 and 3D points from 4 candidate extrinsics
function [P2, pts3d, correct] = findExtrinsic2(P1, P2s, pts1, pts2)
pts3ds = zeros([size(pts1, 1), 3, 4]);
numPointsWithPosDepth = zeros(4, 1);
for i = 1:4
    pts3ds(:, :, i) = triangulate(P1, pts1, P2s(:, :, i), pts2);
    numPointsWithPosDepth(i) = sum(pts3ds(:, 3, i) > 0);
end
[~, correct] = max(numPointsWithPosDepth);
P2 = P2s(:, :, correct);
pts3d = pts3ds(:, :, correct);
end

%% Compute reprojection error of triangulate
function [err1, err2] = reprojectTriangulated(P1, P2, pts1, pts2, pts3d)
N = size(pts3d, 1);
pts1_proj = [pts3d, ones(N,1)] * P1';
pts1_proj = pts1_proj(:,1:2) ./ pts1_proj(:,3);
pts2_proj = [pts3d, ones(N,1)] * P2';
pts2_proj = pts2_proj(:,1:2) ./ pts2_proj(:,3);
err1 = mean(vecnorm(pts1_proj - pts1, 2, 2));
err2 = mean(vecnorm(pts2_proj - pts2, 2, 2));

end
