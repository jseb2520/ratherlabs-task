#!/bin/bash

# Function to deploy the LINK Token Mock contract
deployLinkTokenMock() {
    echo "Deploying LINK Token Mock..."
    LINK_TOKEN_ADDRESS=$(npx hardhat run scripts/deployLinkTokenMock.js --network ganache | grep "LINK Token Mock deployed to:" | awk '{print $NF}')
}

# Function to deploy the MockVRF Coordinator
deployMockVRFCoordinator() {
    echo "Deploying MockVRFCoordinator..."
    MOCK_VRF_COORDINATOR_ADDRESS=$(npx hardhat run scripts/deployMockVRFCoordinator.js --network ganache | grep "MockVRFCoordinator deployed to:" | awk '{print $NF}')
}

# Function to deploy the Governance Token and DAO contracts
deployContracts() {
    echo "Deploying Governance Token and DAO contracts..."
    GOVERNANCE_TOKEN_ADDRESS=$(npx hardhat run scripts/deployGovernanceToken.js --network ganache | grep "Governance Token deployed to:" | awk '{print $NF}')
    DAO_ADDRESS=$(npx hardhat run scripts/deployDAO.js --network ganache $LINK_TOKEN_ADDRESS $MOCK_VRF_COORDINATOR_ADDRESS $GOVERNANCE_TOKEN_ADDRESS | grep "DAO deployed to:" | awk '{print $NF}')
}

# Function to grant voting rights
grantVotingRights() {
    echo "Granting voting rights..."
    npx hardhat run scripts/grantVotingRights.js --network ganache $DAO_ADDRESS
}

# Function to create a new proposal
createProposal() {
    echo "Creating a new proposal..."
    npx hardhat run scripts/createProposal.js --network ganache $DAO_ADDRESS
}

# Function to get coordinator address and key hash
getCoordinatorAddressAndKeyHash() {
    echo "Getting Coordinator Address and Key Hash..."
    npx hardhat run scripts/getCoordinatorAddressAndKeyHash.js --network ganache
}

# Function to run tests
runTests() {
    echo "Running tests..."
    npx hardhat test
}

# Deploy the LINK Token Mock
deployLinkTokenMock

# Deploy the MockVRFCoordinator
deployMockVRFCoordinator

# Deploy the Governance Token and DAO contracts
deployContracts

# Grant voting rights (if needed)
grantVotingRights

# Create a new proposal
createProposal

# Get Coordinator Address and Key Hash
getCoordinatorAddressAndKeyHash

# Run tests
runTests
