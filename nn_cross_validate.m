% Performs nfold cross-validation using tr_images/tr_labels on a parameter K
% If tr_identity is provided, uses that to do the split of the training images
% If tr_identity is not provided uses random permutations (disregards similar faces, bias in the training data)

function mean_acc = nn_cross_validate(K, tr_images, tr_labels, nfold, tr_identity)

ntr = size(tr_images, 3);
inputs_train = reshape(tr_images, [1024, ntr]);
targets_train = full(ind2vec(tr_labels'));

if (~exist('tr_identity', 'var'))
  % random permutation (disregards similar faces)
  perm = randperm(ntr); 

  foldsize = floor(ntr/nfold);
  for i=1:nfold-1
    foldids{i} = (i-1)*foldsize+1:(i*foldsize);
  end
  foldids{nfold} = (nfold-1)*foldsize+1:ntr;
else
  % generally one uses random permutation to specify the splits, but because of the special structure of the dataset
  % we use the identity of poeple for this purpose.
  unknown = find(tr_identity == -1);
  tr_identity(unknown) = -(1:length(unknown));
  
  % finding people with the same identity
  [sid ind] = sort(tr_identity); % sid = sorted array; ind = index of original position in tr_identity
  [a b] = unique(sid); % a = unique values; b = index of each value of 'a' in 'sid'
  npeople = length(a);

  % separating out people with the same identity
  people = cell(npeople,1);
  people{1} = ind(1:b(1));
  for i=2:npeople
    people{i} = ind(b(i-1)+1:b(i))';
  end
  
  % shuffling people
  people = people(randperm(npeople));
  
  % dividing people into groups of roughly the same size but not necessarily
  foldsize = floor(npeople/nfold);
  for i=1:nfold-1
    foldids{i} = [people{(i-1)*foldsize+1:(i*foldsize)}];
  end
  foldids{nfold} = [people{(nfold-1)*foldsize+1:npeople}];
end

% perform nfold training and validation
for i=1:nfold
  traini_ids = [foldids{[1:(i-1) (i+1):nfold]}];
  testi_ids = foldids{i};
  
  ids = [traini_ids, testi_ids];

  [predi, acc(i)] = nn_classifier(K, tr_images(:, :, ids), tr_labels(ids));
  
  % display([predi'; tr_labels(testi_ids)']);
  
  %acc(i) = sum(predi' == tr_labels(testi_ids))/length(foldids{i});
end

mean_acc = mean(acc);