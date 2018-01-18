function [matrix_reshape] = removeDiag(matrix)

    % Remove diag elements with zeros
    matrix(logical(eye(size(matrix)))) = 0;
    
    % Lower matrix part
    matrix_tril = tril(matrix); 
    matrix_tril = matrix_tril(2:end,:);
    
    % Upper matrix part
    matrix_triu = triu(matrix); 
    matrix_triu = matrix_triu(1:end-1,:);
    
    % Merge the matrices
    matrix_reshape = matrix_tril + matrix_triu;

